import FWCore.ParameterSet.Config as cms

from PhysicsTools.JetMCAlgos.TauGenJets_cfi import tauGenJets

ttHGenFilter = cms.EDFilter(
    "GenEventFilter",
    genParticles=cms.InputTag('genParticles'),
    genTaus=cms.InputTag('tauGenJets'),
    genJets=cms.InputTag('ak4GenJetsNoNu'),
    leptonID=cms.vint32(11, 13),
    leptonPtLead=cms.vdouble(23, 20),
    leptonPt=cms.vdouble(14, 9),
    leptonEta=cms.vdouble(2.7, 2.7),
    jetPt=cms.double(20),
    jetEta=cms.double(2.7),
    tauPt=cms.double(18),
    tauEta=cms.double(2.7),
    useFakeTaus=cms.bool(False),
    fakeCut=cms.double(0.),
    minLeptons=cms.int32(1),
    minJets=cms.int32(0),
    minTaus=cms.int32(0),
    minTotal=cms.int32(6),
    minTotalLeptons=cms.int32(1)
)

ttHfilter = cms.Sequence(tauGenJets + ttHGenFilter)
