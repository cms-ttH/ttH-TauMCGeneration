import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
    args = cms.vstring('/cvmfs/cms.cern.ch/phys_generator/gridpacks/slc6_amd64_gcc481/13TeV/powheg/V2/ttH_inclusive_NNPDF30_13TeV_M125/v5/ttH_inclusive_NNPDF30_13TeV_M125_tarball.tgz'),
    nEvents = cms.untracked.uint32(5000),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)

#Link to datacards:
# https://github.com/cms-sw/genproductions/blob/d388a1bcbee4578ba0827651eb3f05006ed1d797/bin/Powheg/production/2017/13TeV/ttH_inclusive_hdamp_NNPDF31_13TeV_M125/ttH_inclusive_hdamp_NNPDF31_13TeV_M125.input

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
            'POWHEG:nFinal = 3',   ## Number of final state particles
                                   ## (BEFORE THE DECAYS) in the LHE
                                   ## other than emitted extra parton
            '23:mMin = 0.05',      
	    	'24:mMin = 0.05',      
            '25:m0 = 125.0',
            '25:onMode = on',	   
			'25:offIfAny = 5 -5' #with previous line: decays to all, except bb pair
          ),
        parameterSets = cms.vstring('pythia8CommonSettings',
                                    'pythia8CP5Settings',
				    'pythia8PowhegEmissionVetoSettings',
                                    'processParameters'
                                    )
        )
 )

ProductionFilterSequence = cms.Sequence(generator)
