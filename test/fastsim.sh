scram p CMSSW CMSSW_8_0_20
cd CMSSW_8_0_20/src
curl -s --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIISummer15wmLHEGS-00482 --retry 2 --create-dirs -o Configuration/GenProduction/python/HIG-RunIISummer15wmLHEGS-00482-fragment.py
git clone git@github.com:cms-ttH/ttH-TauMCGeneration.git ttH/TauMCGeneration
eval `scram runtime -sh`
scram b
cd ../..

# ================
# Using private PU
# ================

cmsDriver.py Configuration/GenProduction/python/HIG-RunIISummer15wmLHEGS-00482-fragment.py \
   -n 500 \
   --python_filename all_fast.py \
   --fileout file:all_fast.root \
   --pileup_input "dbs:/Neutrino_E-10_gun/RunIISpring16FSPremix-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1/GEN-SIM-DIGI-RAW" \
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

cmsDriver.py \
   -n 500 \
   --python_filename maod_fast.py \
   --fileout file:moad_fast.root \
   --filein file:all_fast.root \
   --mc --eventcontent MINIAODSIM --fast \
   --datatier MINIAODSIM --conditions auto:run2_mc \
   --step PAT --runUnscheduled \
   --era Run2_25ns \
   --no_exec
