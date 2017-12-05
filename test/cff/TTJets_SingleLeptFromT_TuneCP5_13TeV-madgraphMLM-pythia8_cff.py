import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
    args = cms.vstring('/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/madgraph/V5_2.4.2/tt0123j_1l_t_5f_ckm_LO_MLM/v1/tt0123j_1l_t_5f_ckm_LO_MLM_slc6_amd64_gcc481_CMSSW_7_1_30_tarball.tar.xz'),
    nEvents = cms.untracked.uint32(5000),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)

# Link to datacards:
# https://github.com/cms-sw/genproductions/tree/https://github.com/cms-sw/genproductions/tree/5667587720342d0e9e95dc9dd022c48ec624fcd9/bin/MadGraph5_aMCatNLO/cards/production/13TeV/tt0123j_1l_t_5f_ckm_LO_MLM/

from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi  import *
generator = cms.EDFilter("Pythia8HadronizerFilter",
maxEventsToPrint = cms.untracked.int32(1),
pythiaPylistVerbosity = cms.untracked.int32(1),
filterEfficiency = cms.untracked.double(1.0),
pythiaHepMCVerbosity = cms.untracked.bool(False),
comEnergy = cms.double(13000.),
PythiaParameters = cms.PSet(
pythia8CommonSettingsBlock,
pythia8CP5SettingsBlock,
JetMatchingParameters = cms.vstring(
'JetMatching:setMad = off',
'JetMatching:scheme = 1',
'JetMatching:merge = on',
'JetMatching:jetAlgorithm = 2',
'JetMatching:etaJetMax = 5.',
'JetMatching:coneRadius = 1.',
'JetMatching:slowJetPower = 1',
'JetMatching:qCut = 70.', #this is the actual merging scale
'JetMatching:nQmatch = 5', #4 corresponds to 4-flavour scheme (no matching of b-quarks), 5 for 5-flavour scheme
'JetMatching:nJetMax = 3', #number of partons in born matrix element for highest multiplicity
'JetMatching:doShowerKt = off', #off for MLM matching, turn on for shower-kT matching
),
processParameters = cms.vstring(
'TimeShower:mMaxGamma = 1.0',#cutting off lepton-pair production 
##in the electromagnetic shower to not overlap with ttZ/gamma* samples
  ),                                
parameterSets = cms.vstring('pythia8CommonSettings',
'pythia8CP5Settings',
'JetMatchingParameters','processParameters'
)
)
)
ProductionFilterSequence = cms.Sequence(generator)
