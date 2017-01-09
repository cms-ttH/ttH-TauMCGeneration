from WMCore.Configuration import Configuration

sample = 'ttH'
step = 'aod'
part = 'p5'

config = Configuration()

config.section_('General')
config.General.requestName = '_'.join([sample, step, part])

config.section_('JobType')
config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'configs/{}_{}.py'.format(sample, step)
config.JobType.maxMemoryMB = 4000
config.JobType.numCores = 2

config.section_('Data')
config.Data.inputDataset = '/ttHToNonbb_M125_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8/matze-v1{}-d25b358819e2255ed088b0fdc1f0e0f7/USER'.format(part)
config.Data.inputDBS = 'phys03'
config.Data.ignoreLocality = True
config.Data.splitting = 'LumiBased'
config.Data.unitsPerJob = 100
config.Data.publication = True
config.Data.outputDatasetTag = '{}_v1{}'.format(step, part)

config.section_('Site')
config.Site.storageSite = 'T2_EE_Estonia'
# config.Site.whitelist = ['T2_EE_Estonia']
