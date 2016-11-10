import FWCore.ParameterSet.Config as cms

from ttH.TauMCGeneration.eventFilter_cfi import tauGenJets, ttHGenFilter, ttHfilter

tauGenJets.GenParticles = cms.InputTag('prunedGenParticles')
ttHGenFilter.genParticles = cms.InputTag('prunedGenParticles')
ttHGenFilter.genJets = cms.InputTag('slimmedGenJets')
