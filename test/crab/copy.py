import re

from WMCore.Configuration import Configuration


def generate(dataset):
    m = re.match(r'/[^/]*/matze-(.*)[-_][0-9a-f]+(-v\d+)?/USER', dataset)
    tag = ''.join([str(g) for g in m.groups() if g])
    config = Configuration()

    config.section_('General')
    config.General.requestName = 'yet_another_copy_' + tag

    config.section_('JobType')
    config.JobType.pluginName = 'Analysis'
    config.JobType.psetName = 'configs/copy.py'

    config.section_('Data')
    config.Data.inputDataset = dataset
    config.Data.inputDBS = 'phys03'
    # ignoreLocality will work when running on an arbitrary site, as long
    # as the files are present at a site that's hooked up in the federation
    # (ND is not!)
    # config.Data.ignoreLocality = True
    config.Data.splitting = 'FileBased'
    config.Data.unitsPerJob = 4
    config.Data.publication = True
    config.Data.outputDatasetTag = 'copy_' + tag

    config.section_('Site')
    # Apparently, we are blacklisted on the CRAB server side! Ignore the
    # global blacklist...
    config.Site.ignoreGlobalBlacklist = True
    # config.Site.whitelist = ['T3_US_NotreDame']
    config.Site.storageSite = 'T2_EE_Estonia'
    return config

# config = generate('/ttHToNonbb_M125_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8/matze-faster_v5_ttH_maod_777fc0041cce4fac803f2dbb53a837f5-v1/USER')
config = generate('/ttHToNonbb_M125_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8/matze-tau_v1_train_ttHToNonbb_M125_TuneCUETP8M2_ttHtranche3_13TeV_powheg_pythia8_v1_c0233c4da5eb4e858e2884f3ec6749dc-v1/USER')

print("""
Using the following configuration:
---8<---
{c}
--->8---
""".format(c=config))
