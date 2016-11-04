import FWCore.ParameterSet.Config as cms


def customizeForGenFiltering(process):
    process.ttHGenFilter = cms.EDFilter(
        "GenEventFilter",
        genParticles=cms.InputTag('genParticles'),
        genJets=cms.InputTag('ak4GenJetsNoNu'),
        leptonID=cms.vint32(11, 13),
        leptonPt=cms.vdouble(25, 20),
        leptonEta=cms.vdouble(2.7, 2.7),
        jetPt=cms.double(20),
        jetEta=cms.double(2.7),
        tauPt=cms.double(18),
        tauEta=cms.double(2.7),
        useFakeTaus=cms.bool(False),
        fakeCut=cms.double(-0.155),
        minLeptons=cms.int32(1),
        minJets=cms.int32(3),
        minTaus=cms.int32(0),
        minTotal=cms.int32(6),
        minTotalLeptons=cms.int32(1)
    )
    for path in process.paths:
        if path in ['generation_step', 'lhe_step']:
            continue
        sequence = getattr(process, path)
        if path in ['digitisation_step']:
            sequence *= process.ttHGenFilter
        else:
            sequence.insert(1, process.ttHGenFilter)
    process.overallFilter = cms.Path(process.generation_step * process.ttHGenFilter)
    process.AODSIMoutput.SelectEvents.SelectEvents = cms.vstring('overallFilter')
    return process
