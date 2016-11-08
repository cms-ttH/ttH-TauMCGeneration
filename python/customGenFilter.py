import FWCore.ParameterSet.Config as cms


def customizeForGenFiltering(process):
    process.load("ttH.TauMCGeneration.eventFilter_cfi")
    for path in process.paths:
        if path in ['generation_step', 'lhe_step']:
            continue
        sequence = getattr(process, path)
        if path in ['digitisation_step']:
            sequence *= process.ttHGenFilter
        else:
            sequence.insert(1, process.ttHGenFilter)
    process.ttHfilter_step = cms.Path(process.ttHGenFilter)
    process.schedule.extend([process.ttHfilter_step])
    process.AODSIMoutput.SelectEvents.SelectEvents = cms.vstring('ttHfilter_step')
    return process


def customizeForGenFilteringWithFakes(process):
    process.load("ttH.TauMCGeneration.eventFilter_cfi")
    process.ttHGenFilter.useFakeTaus = cms.bool(True)
    process.ttHGenFilter.minTaus = cms.int32(2)
    process.ttHGenFilter.fakeCut = cms.double(0.)
    for path in process.paths:
        if path in ['generation_step', 'lhe_step']:
            continue
        sequence = getattr(process, path)
        if path in ['digitisation_step']:
            sequence *= process.ttHGenFilter
        else:
            sequence.insert(1, process.ttHGenFilter)
    process.ttHfilter_step = cms.Path(process.ttHGenFilter)
    process.schedule.extend([process.ttHfilter_step])
    process.AODSIMoutput.SelectEvents.SelectEvents = cms.vstring('ttHfilter_step')
    return process
