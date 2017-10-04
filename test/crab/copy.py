import os
import re
import subprocess
import sys

from WMCore.Configuration import Configuration


def generate(dataset):
    _, primary, _, _ = dataset.split('/')
    m = re.match(r'/[^/]*/matze-(.*)[-_][0-9a-f]+(-v\d+)?/USER', dataset)
    tag = ''.join([str(g) for g in m.groups() if g])
    config = Configuration()

    files = subprocess.check_output(['dasgoclient', '-query', 'instance=prod/phys03 file dataset=' + dataset]).splitlines()

    config.section_('General')
    config.General.requestName = 'yet_another_copy_' + tag

    config.section_('JobType')
    config.JobType.pluginName = 'Analysis'
    config.JobType.psetName = 'configs/copy.py'

    config.section_('Data')
    # ignoreLocality will work when running on an arbitrary site, as long
    # as the files are present at a site that's hooked up in the federation
    # (ND is not!)
    config.Data.ignoreLocality = True
    config.Data.splitting = 'FileBased'
    config.Data.unitsPerJob = 4
    config.Data.publication = True
    config.Data.outputDatasetTag = 'copy_' + tag
    config.Data.outputPrimaryDataset = primary
    config.Data.userInputFiles = ['root://deepthought.crc.nd.edu/{}'.format(fn) for fn in files]

    config.section_('Site')
    # Apparently, we are blacklisted on the CRAB server side! Ignore the
    # global blacklist...
    config.Site.ignoreGlobalBlacklist = True
    # config.Site.whitelist = ['T3_US_NotreDame']
    config.Site.storageSite = 'T2_EE_Estonia'

    with open(os.path.join('crab', 'copy_{}.py'.format(tag)), 'w') as fd:
        fd.write(str(config))


try:
    subprocess.check_call(['voms-proxy-info', '-exists', '-valid', '1:00'])
except subprocess.CalledProcessError:
    print("Need a valid proxy!")
    sys.exit(1)

datasets = subprocess.check_output(['dasgoclient', '-query', 'instance=prod/phys03 dataset=/*/matze-faster*lhe*/USER'])
for dataset in datasets.splitlines():
    generate(dataset)
