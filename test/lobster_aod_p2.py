from lobster import cmssw

from lobster.core import AdvancedOptions, Category, Config, StorageConfiguration, Workflow
from lobster.core import ParentDataset, ProductionDataset

version = 'v9'

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

datasets = ['ttW', 'ttZ', 'WZ']
tasksizes = [5000, 5000, 10000]
events = [50e6, 50e6, 150e6]

workflows = []

for dset, tasksize, events in zip(datasets, tasksizes, events):
    tasks = int(events / tasksize)

    aod = Workflow(
        label=dset + '_aod',
        pset='configs/' + dset + '_aod.py',
        dataset=ProductionDataset(
            events_per_task=tasksize,
            events_per_lumi=200,
            number_of_tasks=tasks
        ),
        category=Category(
            name='aod',
            cores=2,
            disk=2000,
            memory=4000
        ),
        sandbox=[
            cmssw.Sandbox(release='/afs/crc.nd.edu/user/m/mwolf3/work/ttH/mcgen/moriond17_part1/CMSSW_8_0_21'),
            cmssw.Sandbox(release='/afs/crc.nd.edu/user/m/mwolf3/work/ttH/mcgen/moriond17_part1_rh7/CMSSW_8_0_21')
        ]
    )

    maod = Workflow(
        label=dset + '_maod',
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
            'cmsxrootd.fnal.gov'
        ]
    )
)
