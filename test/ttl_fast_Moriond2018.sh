set -e
set -x

das=1
setup=1

usage() { echo "usage: $0 [-ds]"; exit 1; }

while getopts "ds" o; do
   case "${o}" in
      d)
         das=0
         ;;
      s)
         setup=0
         ;;
      *)
         usage
         ;;
   esac
done

era=Run2_2017
release=CMSSW_9_4_0
globaltag=94X_mc2017_realistic_v7
premix=/Neutrino_E-10_gun/RunIISummer16FSPremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v4-v1/GEN-SIM-DIGI-RAW
hlt=2e34_v2
beamspot=Realistic25ns13TeVEarly2017Collision

## Moriond 2017
# globaltag=80X_mcRun2_asymptotic_2016_TrancheIV_v6
# hlt=@frozen2016
# beamspot=Realistic50ns13TeVCollision


declare -A setups

setups[ttH]=python/ThirteenTeV/Higgs/ttHJetToNonbb_M125_13TeV_amcatnloFXFX_madspin_pythia8_cff.py
# setups[ttjets_dl]=python/HIG-RunIISummer15wmLHEGS-00481-fragment.py
# setups[ttjets_sl]=python/HIG-RunIISummer15wmLHEGS-00482-fragment.py
# setups[WZ]="python/SMP-RunIIWinter15wmLHE-00019-fragment.py python/SMP-RunIISummer15GS-00015-fragment.py"
# setups[ttW]=python/TOP-RunIISummer15wmLHEGS-00012-fragment.py
# setups[ttZ]=python/TOP-RunIISummer15wmLHEGS-00013-fragment.py

Init_proxy()
{
    voms-proxy-info -exists
    if [ $das -eq 1 -a $? -eq 1 ]; then
        echo "need a valid proxy"
        exit 1
    fi
}

Init_CMSSW()
{
    if [ $setup -eq 1 ]; then
        scram p CMSSW $release
        cd $release/src
    fi
}

Get_fragments()
{
    for cfgs in "${setups[@]}"; do
        for cfg in $cfgs; do
            if [[ $cfg =~ fragment ]]; then
                fn=${cfg##*/}
                frag=${fn%-fragment.py}
                cfg=${cfg//-/_}
                remote_path="--insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/"
                remote_path=${remote_path}${frag}
            else
                remote_path="https://raw.githubusercontent.com/cms-sw/genproductions/ec41da72f49da415238cff8d11b2c8ab5b685f14/"
                remote_path=${remote_path}${cfg}
            fi
            curl -s ${remote_path} \
                --retry 2 \
                --create-dirs \
                -o Configuration/GenProduction/$cfg
        done
    done
}

Get_repo()
{
    if [ $setup -eq 1 ]; then
        git clone https://github.com/cms-ttH/ttH-TauMCGeneration.git \
            ttH/TauMCGeneration
        eval `scram runtime -sh`
        scram b
    fi
}

Produce_PU_lookup()
{
    if [ $das -eq 1 ]; then
        das_client.py --limit=0 --query="file dataset=$premix" > pufiles.txt
    fi
}

Run_AOD_in_1step()
{
    sample=$1
    config=$2
    filter=$3
    
    cmsDriver.py Configuration/GenProduction/python/tmp_fragment.py \
        -n 100 \
        --python_filename ${sample}_aod.py \
        --fileout file:${sample}_aod.root \
        --pileup_input "[]" \
        --mc \
        --eventcontent AODSIM \
        --fast \
        --customise SimGeneral/DataMixingModule/customiseForPremixingInput.customiseForPreMixingInput \
        $filter \
        --datatier AODSIM \
        --conditions $globaltag \
        --beamspot ${beamspot} \
        --step LHE,GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:$hlt \
        --datamix PreMix \
        --era $era \
        --no_exec
}

Run_AOD_in_2steps()
{
    sample=$1
    config=$2
    filter=$3
    
    cmsDriver.py Configuration/GenProduction/$config \
        -n 100 \
        --python_filename ${sample}_lhe.py \
        --fileout file:${sample}_lhe.root \
        --mc \
        --eventcontent LHE \
        --datatier LHE \
        --fast \
        --conditions $globaltag \
        --beamspot ${beamspot} \
        --step LHE \
        --era $era \
        --no_exec

    cmsDriver.py Configuration/GenProduction/$config \
        -n 100 \
        --python_filename ${sample}_aod.py \
        --fileout file:${sample}_aod.root \
        --filein file:${sample}_lhe.root \
        --pileup_input "[]" \
        --mc \
        --eventcontent AODSIM \
        --fast \
        --customise SimGeneral/DataMixingModule/customiseForPremixingInput.customiseForPreMixingInput \
        $filter \
        --datatier AODSIM \
        --conditions $globaltag \
        --beamspot ${beamspot} \
        --step GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:$hlt \
        --datamix PreMix \
        --era $era \
        --no_exec
}

Run_MAOD_step()
{
    sample=$1
    
    cmsDriver.py \
        -n 100 \
        --python_filename ${sample}_maod.py \
        --fileout file:${sample}_maod.root \
        --filein file:${sample}_aod.root \
        --mc \
        --eventcontent MINIAODSIM \
        --fast \
        --datatier MINIAODSIM \
        --conditions $globaltag \
        --step PAT \
        --runUnscheduled \
        --era $era \
        --no_exec
}

Make_cfgs()
{
    sample=$1
    config=$2
    filter=$3

    config=${config//-/_}
    cat ${config//python/Configuration\/GenProduction\/python} >> \
        Configuration/GenProduction/python/tmp_fragment.py

    if [[ $sample =~ ttW || $sample =~ ttZ || $sample =~ WZ ]]; then
        Run_AOD_in_1step "${sample}" "${config}" "${filter}"
    else
        Run_AOD_in_2steps "${sample}" "${config}" "${filter}"
    fi

    rm Configuration/GenProduction/python/tmp_fragment.py

    # Add premix part to the AOD py
    cat <<EOF >>${sample}_aod.py
import os
process.mixData.input.fileNames = cms.untracked.vstring([])
with open(os.path.join(os.environ['LOCALRT'],
                       'src/ttH/TauMCGeneration/data/pufiles.txt')) as fd:
    for line in fd:
        process.mixData.input.fileNames.append(line.strip())
EOF

    Run_MAOD_step "${sample}"
}

#
# Execute
#
Init_proxy
Init_CMSSW
Get_fragments
Get_repo
Produce_PU_lookup

for smpl in "${!setups[@]}"; do
    cfg="${setups[$smpl]}"
    fltr="--customise ttH/TauMCGeneration/customGenFilter.customizeForGenFilteringWithFakes"

    # Make_cfgs $smpl $cfg ""
    # Make_cfgs ${smpl}_filtered $cfg "$fltr"
    Make_cfgs ${smpl} "$cfg" "$fltr"
done
