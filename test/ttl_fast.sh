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

era=Run2_2016
release=CMSSW_8_0_21
globaltag=80X_mcRun2_asymptotic_2016_TrancheIV_v6
premix=/Neutrino_E-10_gun/RunIISummer16FSPremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v4-v1/GEN-SIM-DIGI-RAW

declare -A setups

# setups[ttH]=python/HIG-RunIISummer15wmLHEGS-00484-fragment.py
# setups[ttjets_dl]=python/HIG-RunIISummer15wmLHEGS-00481-fragment.py
# setups[ttjets_sl]=python/HIG-RunIISummer15wmLHEGS-00482-fragment.py
setups[WZ]="python/SMP-RunIIWinter15wmLHE-00019-fragment.py python/SMP-RunIISummer15GS-00015-fragment.py"
setups[ttW]=python/TOP-RunIISummer15wmLHEGS-00012-fragment.py
setups[ttZ]=python/TOP-RunIISummer15wmLHEGS-00013-fragment.py

if [ $setup -eq 1 ]; then
   scram p CMSSW $release
   cd $release/src
fi

for cfgs in "${setups[@]}"; do
   for cfg in $cfgs; do
      if [[ $cfg =~ fragment ]]; then
         fn=${cfg##*/}
         frag=${fn%-fragment.py}
         cfg=${cfg//-/_}
         curl -s --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/$frag --retry 2 --create-dirs -o Configuration/GenProduction/$cfg
      else
         curl -s https://raw.githubusercontent.com/cms-sw/genproductions/2f28097e385e7a217a839f59e180fa9b38d89e15/$cfg --retry 2 --create-dirs -o Configuration/GenProduction/$cfg
      fi
   done
done

if [ $setup -eq 1 ]; then
   git clone git@github.com:cms-ttH/ttH-TauMCGeneration.git ttH/TauMCGeneration
   eval `scram runtime -sh`
   scram b
   cd ../..
fi

if [ $das -eq 1 ]; then
   das_client.py --limit=0 --query="file dataset=$premix" > pufiles.txt
fi

mk_cfg() {
   sample=$1
   config=$2
   filter=$3

   config=${config//-/_}
   cat ${config//python/Configuration\/GenProduction\/python} >> Configuration/GenProduction/python/tmp_fragment.py

   if [[ $sample =~ ttW || $sample =~ ttZ || $sample =~ WZ ]]; then
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
         --beamspot Realistic50ns13TeVCollision \
         --step LHE,GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:@frozen2016 \
         --datamix PreMix \
         --era $era \
         --no_exec
   else
      cmsDriver.py Configuration/GenProduction/$config \
         -n 100 \
         --python_filename ${sample}_lhe.py \
         --fileout file:${sample}_lhe.root \
         --mc \
         --eventcontent LHE \
         --datatier LHE \
         --fast \
         --conditions $globaltag \
         --beamspot Realistic50ns13TeVCollision \
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
         --beamspot Realistic50ns13TeVCollision \
         --step GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:@frozen2016 \
         --datamix PreMix \
         --era $era \
         --no_exec
   fi

   rm Configuration/GenProduction/python/tmp_fragment.py

   cat <<EOF >>${sample}_aod.py
process.mixData.input.fileNames = cms.untracked.vstring([])
import os
with open(os.path.join(os.environ['LOCALRT'], 'src/ttH/TauMCGeneration/data/pufiles.txt')) as fd:
    for line in fd:
       process.mixData.input.fileNames.append(line.strip())
EOF
   cmsDriver.py \
      -n 100 \
      --python_filename ${sample}_maod.py \
      --fileout file:${sample}_maod.root \
      --filein file:${sample}_aod.root \
      --mc --eventcontent MINIAODSIM --fast \
      --datatier MINIAODSIM --conditions $globaltag \
      --step PAT --runUnscheduled \
      --era $era \
      --no_exec
}

for smpl in "${!setups[@]}"; do
   cfg="${setups[$smpl]}"
   fltr="--customise ttH/TauMCGeneration/customGenFilter.customizeForGenFilteringWithFakes"

   # mk_cfg $smpl $cfg ""
   # mk_cfg ${smpl}_filtered $cfg "$fltr"
   mk_cfg ${smpl} "$cfg" "$fltr"
done
