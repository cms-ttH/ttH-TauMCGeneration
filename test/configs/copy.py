import FWCore.ParameterSet.Config as cms

process = cms.Process('copy')

process.source = cms.Source("PoolSource", fileNames=cms.untracked.vstring())
process.output = cms.OutputModule("PoolOutputModule",
                                  outputCommands=cms.untracked.vstring('keep *'),
                                  fileName=cms.untracked.string('o.root'))

process.out = cms.EndPath(process.output)
