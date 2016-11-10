set -e
set -x

release=CMSSW_8_0_14

declare -A setups

setups[ttH]=python/HIG-RunIISummer15wmLHEGS-00484-fragment.py
setups[ttjets_dl]=python/HIG-RunIISummer15wmLHEGS-00481-fragment.py
setups[ttjets_sl]=python/HIG-RunIISummer15wmLHEGS-00482-fragment.py

scram p CMSSW $release
cd $release/src

for cfg in "${setups[@]}"; do
   if [[ $cfg =~ fragment ]]; then
      fn=${cfg##*/}
      frag=${fn%-fragment.py}
      cfg=${cfg//-/_}
      curl -s --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/$frag --retry 2 --create-dirs -o Configuration/GenProduction/$cfg
   else
      curl -s https://raw.githubusercontent.com/cms-sw/genproductions/2f28097e385e7a217a839f59e180fa9b38d89e15/$cfg --retry 2 --create-dirs -o Configuration/GenProduction/$cfg
   fi
done

git clone git@github.com:cms-ttH/ttH-TauMCGeneration.git ttH/TauMCGeneration
eval `scram runtime -sh`
scram b
cd ../..

mk_cfg() {
   sample=$1
   config=$2
   filter=$3

   config=${config//-/_}

   cmsDriver.py Configuration/GenProduction/$config \
      -n 500 \
      --python_filename fast_${sample}_aod.py \
      --fileout file:fast_${sample}_aod.root \
      --pileup_input "dbs:/Neutrino_E-10_gun/RunIISpring16FSPremix-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1/GEN-SIM-DIGI-RAW" \
      --mc \
      --eventcontent AODSIM \
      --fast \
      --customise SimGeneral/DataMixingModule/customiseForPremixingInput.customiseForPreMixingInput \
      $filter \
      --datatier AODSIM \
      --conditions 80X_mcRun2_asymptotic_v14 \
      --beamspot Realistic50ns13TeVCollision \
      --step LHE,GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:25ns10e33_v2 \
      --datamix PreMix \
      --era Run2_25ns \
      --no_exec \

   cmsDriver.py \
      -n 500 \
      --python_filename fast_${sample}_maod.py \
      --fileout file:fast_${sample}_maod.root \
      --filein file:fast_${sample}_aod.root \
      --mc --eventcontent MINIAODSIM --fast \
      --datatier MINIAODSIM --conditions 80X_mcRun2_asymptotic_v14 \
      --step PAT --runUnscheduled \
      --era Run2_25ns \
      --no_exec
}

for smpl in "${!setups[@]}"; do
   cfg="${setups[$smpl]}"
   fltr="--customise ttH/TauMCGeneration/customGenFilter.customizeForGenFilteringWithFakes"

   mk_cfg $smpl $cfg ""
   mk_cfg ${smpl}_filtered $cfg "$fltr"
done
