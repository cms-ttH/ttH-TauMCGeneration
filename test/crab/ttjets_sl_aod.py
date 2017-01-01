from WMCore.Configuration import Configuration

step = 'aod'
part = 'p4'

config = Configuration()

config.section_('General')
config.General.requestName = '_'.join(['ttjets_sl', step, part])

config.section_('JobType')
config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'configs/ttjets_sl_{}.py'.format(step)
config.JobType.maxMemoryMB = 4000
config.JobType.numCores = 2

config.section_('Data')
config.Data.inputDataset = '/TTToSemilepton_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8/matze-lhe_v1p4-164100aee9d533c58d264867cf4a454c/USER'
config.Data.inputDBS = 'phys03'
config.Data.ignoreLocality = True
config.Data.splitting = 'LumiBased'
config.Data.unitsPerJob = 30
config.Data.publication = True
config.Data.outputDatasetTag = '{}_v1{}'.format(step, part)

config.section_('Site')
config.Site.storageSite = 'T2_EE_Estonia'
# config.Site.whitelist = ['T2_EE_Estonia']
