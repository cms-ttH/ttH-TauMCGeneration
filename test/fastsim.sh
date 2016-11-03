scram p CMSSW CMSSW_8_0_20
cd CMSSW_8_0_20/src
curl -s --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIISummer15wmLHEGS-00482 --retry 2 --create-dirs -o Configuration/GenProduction/python/HIG-RunIISummer15wmLHEGS-00482-fragment.py
git clone git@github.com:cms-ttH/ttH-TauMCGeneration.git ttH/TauMCGeneration
eval `scram runtime -sh`
scram b
cd ../..

# =============
# PU Production
# =============

cmsDriver.py MinBias_13TeV_pythia8_TuneCUETP8M1_cfi \
   --conditions auto:run2_mc --fast -n 500 --era Run2_2016 \
   --eventcontent FASTPU --relval 100000,1000 \
   -s GEN,SIM,RECOBEFMIX --datatier GEN-SIM-RECO --beamspot Realistic50ns13TeVCollision \
   --fileout file:pu_fast.root \
   --python_filename pu_fast.py --no_exec

cmsDriver.py SingleNuE10_cfi \
   --fileout file:premix_fast.root \
   --pileup_input file:pu_fast.root \
   --pileup AVE_35_BX_25ns \
   --mc --eventcontent PREMIX --datatier GEN-SIM-DIGI-RAW --conditions auto:run2_mc \
   --step GEN,SIM,RECOBEFMIX,DIGIPREMIX,L1,DIGI2RAW --era Run2_2016 \
   --python_filename premix_fast.py --no_exec \
   --fast

# ================
# Using private PU
# ================

cmsDriver.py Configuration/GenProduction/python/HIG-RunIISummer15wmLHEGS-00482-fragment.py \
   -n 500 \
   --python_filename all_fast.py \
   --fileout file:all_fast.root \
   --pileup_input file:premix_fast.root \
   --mc \
   --eventcontent AODSIM \
   --fast \
   --customise SimGeneral/DataMixingModule/customiseForPremixingInput.customiseForPreMixingInput \
   --customise ttH/TauMCGeneration/customGenFilter.customizeForGenFiltering \
   --datatier AODSIM \
   --conditions auto:run2_mc \
   --beamspot Realistic50ns13TeVCollision \
   --step LHE,GEN,SIM,RECOBEFMIX,DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,L1Reco,RECO,HLT:@fake1 \
   --datamix PreMix \
   --era Run2_25ns \
   --no_exec \
