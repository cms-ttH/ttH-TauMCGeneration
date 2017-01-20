import os

from lobster import cmssw

from lobster.core import AdvancedOptions, Category, Config, StorageConfiguration, Workflow
from lobster.core import ParentDataset

version = 'v8'

storage = StorageConfiguration(
    output=[
        "hdfs://eddie.crc.nd.edu:19000/store/user/matze/ttH/fastsim_" + version,
        "file:///hadoop/store/user/matze/ttH/fastsim_" + version,
        "root://deepthought.crc.nd.edu//store/user/matze/ttH/fastsim_" + version,
        "gsiftp://T3_US_NotreDame/store/user/matze/ttH/fastsim_" + version,
        # "chirp://eddie.crc.nd.edu:9094/store/user/matze/ttH/fastsim_" + version,
        # "srm://T3_US_NotreDame/store/user/matze/ttH/fastsim_" + version,
    ]
)

datasets = ['ttH', 'ttjets_sl', 'ttjets_dl']
workflows = []

with open(os.path.join(os.path.dirname(__file__), 'lhe.txt')) as fd:
    lhe = [l.strip() for l in fd.readlines()]

counter = {}

for path in lhe:
    for dset in datasets:
        if dset in path.split('/')[2]:
            break
    else:
        raise ValueError("can't find dataset associated with {}".format(path))

    part = counter.get(dset, 1)
    counter[dset] = part + 1

    aod = Workflow(
        label='{}_aod_p{}'.format(dset, part),
        pset='configs/' + dset + '_aod.py',
        dataset=cmssw.Dataset(
            dataset=path,
            dbs_instance='phys03',
            lumis_per_task=4
        ),
        category=Category(
            name='aod',
            cores=2,
            disk=1000,
            memory=3000,
            runtime=120 * 60
        ),
        sandbox=[
            cmssw.Sandbox(release='/afs/crc.nd.edu/user/m/mwolf3/work/ttH/mcgen/moriond17_part1/CMSSW_8_0_21'),
            cmssw.Sandbox(release='/afs/crc.nd.edu/user/m/mwolf3/work/ttH/mcgen/moriond17_part1_rh7/CMSSW_8_0_21')
        ]
    )

    maod = Workflow(
        label='{}_maod_p{}'.format(dset, part),
        pset='configs/' + dset + '_maod.py',
        merge_size='2000M',
        cleanup_input=True,
        dataset=ParentDataset(
            parent=aod,
            units_per_task=100
        ),
        category=Category(
            name='maod',
            cores=2,
            disk=4000,
            memory=2000,
            runtime=90 * 60
        ),
        sandbox=[
            cmssw.Sandbox(release='/afs/crc.nd.edu/user/m/mwolf3/work/ttH/mcgen/moriond17_part1/CMSSW_8_0_21'),
            cmssw.Sandbox(release='/afs/crc.nd.edu/user/m/mwolf3/work/ttH/mcgen/moriond17_part1_rh7/CMSSW_8_0_21')
        ]
    )

    workflows.extend([aod, maod])

config = Config(
    label='faster_' + version,
    workdir='/tmpscratch/users/matze/ttH/fastsim_' + version,
    plotdir='~/www/lobster/ttH/fastsim_' + version,
    storage=storage,
    workflows=workflows,
    advanced=AdvancedOptions(
        log_level=1,
        xrootd_servers=[
            'ndcms.crc.nd.edu',
            'deepthought.crc.nd.edu',
            'cmsxrootd.fnal.gov'
        ]
    )
)
