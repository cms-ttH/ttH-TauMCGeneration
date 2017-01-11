import FWCore.ParameterSet.Config as cms


def customizeForGenFiltering(process):
    process.load("ttH.TauMCGeneration.eventFilter_cfi")
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
    process.AODSIMoutput.SelectEvents.SelectEvents = cms.vstring('generation_step')
    return process


def customizeForGenFilteringWithFakes(process):
    process = customizeForGenFiltering(process)
    process.ttHGenFilter.useFakeTaus = cms.bool(True)
    process.ttHGenFilter.useFakeTauMVA = cms.bool(True)
    process.ttHGenFilter.minTaus = cms.int32(0)
    process.ttHGenFilter.minTotalLeptons = cms.int32(3)
    return process
