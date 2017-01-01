from WMCore.Configuration import Configuration

step = 'maod'
part = 'p1'

config = Configuration()

config.section_('General')
config.General.requestName = '_'.join(['ttjets_sl', step, part])

config.section_('JobType')
config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'configs/ttjets_sl_{}.py'.format(step)
config.JobType.maxMemoryMB = 2200
config.JobType.numCores = 2

config.section_('Data')
config.Data.inputDataset = '/TTToSemilepton_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8/matze-aod_v1p1-43fa3cd018b40478b3fa4f9b0acb4896/USER'
config.Data.inputDBS = 'phys03'
config.Data.ignoreLocality = True
config.Data.splitting = 'LumiBased'
config.Data.unitsPerJob = 300
config.Data.publication = True
config.Data.outputDatasetTag = '{}_v1{}'.format(step, part)

config.section_('Site')
config.Site.storageSite = 'T2_EE_Estonia'
# config.Site.whitelist = ['T2_EE_Estonia']
