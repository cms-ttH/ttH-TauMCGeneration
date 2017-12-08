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

## WIP 2018 AOD/MAOD
era=Run2_2017
release_FS=CMSSW_9_4_0
globaltag_FS=94X_mc2017_realistic_v7
premix=/Neutrino_E-10_gun/RunIISummer16FSPremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v4-v1/GEN-SIM-DIGI-RAW

## Moriond 2017
# globaltag=80X_mcRun2_asymptotic_2016_TrancheIV_v6
# hlt=@frozen2016
# beamspot=Realistic50ns13TeVCollision


declare -A setups

setups[ttH]=HIG-RunIIFall17wmLHEGS-00044-fragment.py
# setups[ttjets_dl]=TOP-RunIIFall17wmLHEGS-00001-fragment.py
# setups[ttjets_sl]=TOP-RunIIFall17wmLHEGS-00002-fragment.py
# setups[ttW]=HIG-RunIIFall17wmLHEGS-00040-fragment.py
# setups[ttWW]=TOP-RunIIFall17wmLHEGS-00066-fragment.py
# setups[ttZ]=HIG-RunIIFall17wmLHEGS-00041-fragment.py
# setups[WZ]=SMP-RunIIFall17wmLHEGS-00003-fragment.py

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
        eval `scram runtime -sh`
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
                remote_path="https://raw.githubusercontent.com/cms-sw/genproductions/6c354c4e733ae957afffe0a8a73ec13435cfd8a3/"
                remote_path=${remote_path}${cfg}
            fi
            curl -s ${remote_path} \
                --retry 2 \
                --create-dirs \
                -o Configuration/GenProduction/$cfg
        done
    done
}

Copy_fragments()
{
    # Existence of ttH/TauMCGeneration is imposed
    if [ $setup -eq 1 ]; then
        cp -r ttH/TauMCGeneration/Configuration .
        scram b
    fi
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

    cmsDriver.py Configuration/GenProduction/python/${config} \
        -n 100 \
        --python_filename ${sample}_aod.py \
        --fileout file:${sample}_aod.root \
        --mc \
        --eventcontent AODSIM \
        --fast \
        $filter \
        --datatier AODSIM \
        --conditions $globaltag \
        --beamspot ${beamspot} \
        --step LHE,GEN,SIM,L1,DIGI2RAW,L1Reco,RECO \
        --era $era \
        --no_exec
}
#--pileup_input "[]" \
# --step LHE,GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:$hlt \
#--datamix PreMix \
#--customise SimGeneral/DataMixingModule/customiseForPremixingInput.customiseForPreMixingInput \

Run_AOD_in_2steps_2()
{
    sample=$1
    config=$2
    filter=$3
    
    cmsDriver.py Configuration/GenProduction/python/${config} \
        -n 100 \
        --python_filename ${sample}_aod.py \
        --fileout file:${sample}_aod.root \
        --filein file:${sample}_lhe.root \
        --mc \
        --eventcontent AODSIM \
        --fast \
        $filter \
        --datatier AODSIM \
        --conditions ${globaltag_FS} \
        --beamspot ${beamspot} \
        --step GEN,SIM,L1,DIGI2RAW,L1Reco,RECO \
        --era $era \
        --no_exec
}
#--step GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:$hlt \
#--datamix PreMix \
# --pileup_input "[]" \
#--customise SimGeneral/DataMixingModule/customiseForPremixingInput.customiseForPreMixingInput \

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
    
    # AOD
    Run_AOD_in_2steps_2 "${sample}" "${config}" "${filter}"

    # Add premix part to the AOD py
    #cat <<EOF >>${sample}_aod.py
#import os
#process.mixData.input.fileNames = cms.untracked.vstring([])
#with open(os.path.join(os.environ['LOCALRT'],
#                       'src/ttH/TauMCGeneration/data/pufiles.txt')) as fd:
#    for line in fd:
#        process.mixData.input.fileNames.append(line.strip())
#EOF

    Run_MAOD_step "${sample}"
}

#
# Execute
#
#Init_proxy
Init_CMSSW
Get_repo
Copy_fragments
#Get_fragments
#Produce_PU_lookup

for smpl in "${!setups[@]}"; do
    cfg="${setups[$smpl]}"
    fltr="--customise ttH/TauMCGeneration/customGenFilter.customizeForGenFilteringWithFakes"

    Make_cfgs "${smpl}" "$cfg" "$fltr"
done
