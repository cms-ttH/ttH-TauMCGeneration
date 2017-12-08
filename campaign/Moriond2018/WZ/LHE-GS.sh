#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_3_4/src ] ; then 
 echo release CMSSW_9_3_4 already exists
else
scram p CMSSW CMSSW_9_3_4
fi
cd CMSSW_9_3_4/src
eval `scram runtime -sh`

curl -s \
    --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/SMP-RunIIFall17wmLHEGS-00003 \
    --retry 2 --create-dirs \
    -o Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00003-fragment.py 
[ -s Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00003-fragment.py ] || exit $?;

scram b
cd ../../
cmsDriver.py Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00003-fragment.py \
    --fileout file:SMP-RunIIFall17wmLHEGS-00003.root \
    --mc \
    --eventcontent RAWSIM,LHE \
    --datatier GEN-SIM,LHE \
    --conditions 93X_mc2017_realistic_v3 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step LHE,GEN,SIM \
    --nThreads 8 \
    --geometry DB:Extended \
    --era Run2_2017 \
    --python_filename SMP-RunIIFall17wmLHEGS-00003_1_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n 850 || exit $? ; 

