scram p CMSSW CMSSW_7_1_25
cd CMSSW_7_1_25/src
curl -s --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIISummer15wmLHEGS-00482 --retry 2 --create-dirs -o Configuration/GenProduction/python/HIG-RunIISummer15wmLHEGS-00482-fragment.py
eval `scram runtime -sh`
scram b
cd ../..
cmsDriver.py Configuration/GenProduction/python/HIG-RunIISummer15wmLHEGS-00482-fragment.py \
   --fileout file:HIG-RunIISummer15wmLHEGS-00482_full.root \
   --mc --eventcontent RAWSIM,LHE \
   --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring \
   --datatier GEN-SIM,LHE --conditions MCRUN2_71_V1::All --beamspot Realistic50ns13TeVCollision \
   --step LHE,GEN,SIM --magField 38T_PostLS1 \
   --python_filename HIG-RunIISummer15wmLHEGS-00482_1_cfg_full.py --no_exec -n 50

scram p CMSSW CMSSW_8_0_14
cd CMSSW_8_0_14/src
eval `scram runtime -sh`
scram b
cd ../..

cmsDriver.py step1 \
   --filein "file:HIG-RunIISummer15wmLHEGS-00482_full.root" \
   --fileout file:HIG-RunIISpring16DR80-01830_step1_full.root \
   --pileup_input "dbs:/Neutrino_E-10_gun/RunIISpring15PrePremix-PU2016_80X_mcRun2_asymptotic_v14-v2/GEN-SIM-DIGI-RAW" \
   --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 80X_mcRun2_asymptotic_v14 \
   --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:25ns10e33_v2 --nThreads 4 --datamix PreMix --era Run2_2016 \
   --python_filename HIG-RunIISpring16DR80-01830_1_cfg_full.py --no_exec \
   --customise Configuration/DataProcessing/Utils.addMonitoring -n 960

cmsDriver.py step2 \
   --filein file:HIG-RunIISpring16DR80-01830_step1_full.root \
   --fileout file:HIG-RunIISpring16MiniAODv2-02983_full.root \
   --conditions 80X_mcRun2_asymptotic_v14 \
   --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM \
   --step RAW2DIGI,RECO,PAT --nThreads 4 --era Run2_2016 \
   --python_filename HIG-RunIISpring16MiniAODv2-02983_1_cfg_full.py --no_exec \
   --customise Configuration/DataProcessing/Utils.addMonitoring -n 960 || exit $? ;
