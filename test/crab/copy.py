import re

from WMCore.Configuration import Configuration


def generate(dataset):
    m = re.match(r'/[^/]*/matze-(.*)[-_][0-9a-f]+(-v\d+)?/USER', dataset)
    tag = ''.join([str(g) for g in m.groups() if g])
    config = Configuration()

    config.section_('General')
    config.General.requestName = 'copy_' + tag

    config.section_('JobType')
    config.JobType.pluginName = 'Analysis'
    config.JobType.psetName = 'configs/copy.py'

    config.section_('Data')
    config.Data.inputDataset = dataset
    config.Data.inputDBS = 'phys03'
    config.Data.splitting = 'FileBased'
    config.Data.unitsPerJob = 4
    config.Data.publication = True
    config.Data.outputDatasetTag = 'copy_' + tag

    config.section_('Site')
    config.Site.storageSite = 'T2_EE_Estonia'
    return config

config = generate('/ttHToNonbb_M125_TuneCUETP8M2_ttHtranche3_13TeV-powheg-pythia8/matze-faster_v5_ttH_maod_777fc0041cce4fac803f2dbb53a837f5-v1/USER')

print("""
Using the following configuration:
---8<---
{c}
--->8---
""".format(c=config))
