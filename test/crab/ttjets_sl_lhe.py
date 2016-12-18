from WMCore.Configuration import Configuration

step = 'lhe'
part = 'p4'

config = Configuration()

config.section_('General')
config.General.requestName = '_'.join(['ttjets_sl', step, part])

config.section_('JobType')
config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = 'configs/ttjets_sl_lhe.py'
config.JobType.eventsPerLumi = 1000

config.section_('Data')
config.Data.outputPrimaryDataset = 'TTToSemilepton_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = 50 * 1000
config.Data.totalUnits = 200 * 1000 * 1000
config.Data.publication = True
config.Data.outputDatasetTag = '{}_v1{}'.format(step, part)

config.section_('Site')
config.Site.storageSite = 'T2_EE_Estonia'
# config.Site.whitelist = ['T2_EE_Estonia']
