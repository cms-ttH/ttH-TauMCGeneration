set -e
set -x

era=Run2_2016
release=CMSSW_8_0_21
globaltag=80X_mcRun2_asymptotic_2016_TrancheIV_v6
premix=/Neutrino_E-10_gun/RunIISummer16FSPremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v4-v1/GEN-SIM-DIGI-RAW

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
      --pileup_input "dbs:$premix" \
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
   mk_cfg ${smpl} $cfg "$fltr"
done
