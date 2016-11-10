import FWCore.ParameterSet.Config as cms


def customizeForGenFiltering(process):
    process.load("PhysicsTools.JetMCAlgos.TauGenJets_cfi")
    process.load("ttH.TauMCGeneration.eventFilter_cfi")
    process.ttHfilter = cms.Sequence(process.tauGenJets + process.ttHGenFilter)
    for path in process.paths:
        if path in ['lhe_step', 'digitisation_step']:
            continue
        sequence = getattr(process, path)
        if path in ['generation_step']:
            sequence._seq *= process.ttHfilter
        else:
            sequence.insert(1, process.ttHfilter)
    if hasattr(process, 'pdigi'):
        getattr(process, 'pdigi').insert(5, process.ttHfilter)
    process.ttHfilter_step = cms.Path(process.ttHfilter)
    process.schedule.extend([process.ttHfilter_step])
    process.AODSIMoutput.SelectEvents.SelectEvents = cms.vstring('ttHfilter_step')
    return process


def customizeForGenFilteringWithFakes(process):
    process = customizeForGenFiltering(process)
    process.ttHGenFilter.useFakeTaus = cms.bool(True)
    process.ttHGenFilter.minTaus = cms.int32(2)
    process.ttHGenFilter.fakeCut = cms.double(0.)
    return process
