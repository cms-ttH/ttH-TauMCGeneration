import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
    args = cms.vstring('/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/powheg/V2/TT_hvq/TT_hdamp_NNPDF31_NNLO_ljets.tgz'),
    nEvents = cms.untracked.uint32(5000),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)

#Link to datacards:
#https://github.com/jfernan2/genproductions/blob/54a8155135fb7f0d9cef82dbbbbdcdbb59ea55f0/bin/Powheg/production/2017/13TeV/TT_hvq/TT_hdamp_NNPDF31_NNLO_ljets.input


import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *
from Configuration.Generator.Pythia8PowhegEmissionVetoSettings_cfi import *
generator = cms.EDFilter("Pythia8HadronizerFilter",
maxEventsToPrint = cms.untracked.int32(1),
pythiaPylistVerbosity = cms.untracked.int32(1),
filterEfficiency = cms.untracked.double(1.0),
pythiaHepMCVerbosity = cms.untracked.bool(False),
comEnergy = cms.double(13000.),
PythiaParameters = cms.PSet(
pythia8CommonSettingsBlock,
pythia8CP5SettingsBlock,
pythia8PowhegEmissionVetoSettingsBlock,
processParameters = cms.vstring(
        'POWHEG:nFinal = 2', ## Number of final state particles
        ## (BEFORE THE DECAYS) in the LHE
        ## other than emitted extra parton
        'TimeShower:mMaxGamma = 1.0',#cutting off lepton-pair production
        ##in the electromagnetic shower
        ##to not overlap with ttZ/gamma* samples
        '6:m0 = 172.5',    # top mass'
        
        #PSweights
        'UncertaintyBands:doVariations = on',
# 3 sets of variations for ISR&FSR up/down
# Reduced sqrt(2)/(1/sqrt(2)), Default 2/0.5 and Conservative 4/0.25 variations
        'UncertaintyBands:List = {\
isrRedHi isr:muRfac=0.707,fsrRedHi fsr:muRfac=0.707,isrRedLo isr:muRfac=1.414,fsrRedLo fsr:muRfac=1.414,\
isrDefHi isr:muRfac=0.5, fsrDefHi fsr:muRfac=0.5,isrDefLo isr:muRfac=2.0,fsrDefLo fsr:muRfac=2.0,\
isrConHi isr:muRfac=0.25, fsrConHi fsr:muRfac=0.25,isrConLo isr:muRfac=4.0,fsrConLo fsr:muRfac=4.0}',

        'UncertaintyBands:MPIshowers = on',
        'UncertaintyBands:overSampleFSR = 10.0',
        'UncertaintyBands:overSampleISR = 10.0',
        'UncertaintyBands:FSRpTmin2Fac = 20',
        'UncertaintyBands:ISRpTmin2Fac = 1'
),
parameterSets = cms.vstring('pythia8CommonSettings',
'pythia8CP5Settings',
'pythia8PowhegEmissionVetoSettings',
'processParameters'
)
)
)
ProductionFilterSequence = cms.Sequence(generator)
