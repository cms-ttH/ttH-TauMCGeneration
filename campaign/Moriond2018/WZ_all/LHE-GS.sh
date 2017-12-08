#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_3_1/src ] ; then 
 echo release CMSSW_9_3_1 already exists
else
scram p CMSSW CMSSW_9_3_1
fi
cd CMSSW_9_3_1/src
eval `scram runtime -sh`

curl -s \
    --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/B2G-RunIIFall17GS-00002 \
    --retry 2 --create-dirs \
    -o Configuration/GenProduction/python/B2G-RunIIFall17GS-00002-fragment.py 
[ -s Configuration/GenProduction/python/B2G-RunIIFall17GS-00002-fragment.py ] || exit $?;

scram b
cd ../../
cmsDriver.py Configuration/GenProduction/python/B2G-RunIIFall17GS-00002-fragment.py \
    --fileout file:B2G-RunIIFall17GS-00002.root \
    --mc \
    --eventcontent RAWSIM \
    --datatier GEN-SIM \
    --conditions 93X_mc2017_realistic_v3 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step GEN,SIM \
    --nThreads 8 \
    --geometry DB:Extended \
    --era Run2_2017 \
    --python_filename B2G-RunIIFall17GS-00002_1_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n 1098 || exit $? ; 

