from WMCore.Configuration import Configuration

part = 'p5'

config = Configuration()

config.section_('General')
config.General.requestName = 'ttH_lhe_' + part

config.section_('JobType')
config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = 'configs/ttH_lhe.py'

config.section_('Data')
config.Data.outputPrimaryDataset = 'ttHToNonbb_M125_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = 1000
config.Data.totalUnits = 10 * 1000 * 1000
config.Data.publication = True
config.Data.outputDatasetTag = 'v1' + part

config.section_('Site')
config.Site.storageSite = 'T2_EE_Estonia'
config.Site.whitelist = ['T2_EE_Estonia']
