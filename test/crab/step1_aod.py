from WMCore.Configuration import Configuration

sample = 'ttW'
step = 'aod'
part = 'p1'

nevents = int(25e6)
njobevents = nevents / 10000

config = Configuration()

config.section_('General')
config.General.requestName = '_'.join([sample, step, part])

config.section_('JobType')
config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = 'configs/{}_{}.py'.format(sample, step)
config.JobType.maxMemoryMB = 4000
config.JobType.numCores = 2

config.section_('Data')
config.Data.outputPrimaryDataset = 'TTWJetsToLNu_TuneCUETP8M1_13TeV-amcatnloFXFX-madspin-pythia8'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = njobevents
config.Data.totalUnits = nevents
config.Data.publication = True
config.Data.outputDatasetTag = '{}_v1{}'.format(step, part)

config.section_('Site')
config.Site.storageSite = 'T2_EE_Estonia'
config.Site.whitelist = ['T2_EE_Estonia']
