from lobster.core import AdvancedOptions, Category, Config, StorageConfiguration, Workflow
from lobster.core import ParentDataset, ProductionDataset

version = 'v6'

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
tasksizes = [200, 10000, 10000]
events = [20e6, 200e6, 100e6]

workflows = []

for dset, tasksize, events in zip(datasets, tasksizes, events):
    tasks = int(events / tasksize)

    lhe = Workflow(
        label=dset + '_lhe',
        pset='configs/' + dset + '_lhe.py',
        merge_size='2000M',
        dataset=ProductionDataset(
            events_per_task=tasksize,
            events_per_lumi=200,
            number_of_tasks=tasks
        ),
        category=Category(
            name='lhe',
            cores=2,
            disk=2000,
            memory=2000
        )
    )

    aod = Workflow(
        label=dset + '_aod',
        pset='configs/' + dset + '_aod.py',
        dataset=ParentDataset(
            parent=lhe,
            units_per_task=4
        ),
        category=Category(
            name='aod',
            cores=2,
            disk=1000,
            memory=3000,
            runtime=120 * 60
        )
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
        )
    )

    workflows.extend([lhe, aod, maod])

config = Config(
    label='faster_' + version,
    workdir='/tmpscratch/users/matze/ttH/fastsim_' + version,
    plotdir='~/www/lobster/ttH/fastsim_' + version,
    storage=storage,
    workflows=workflows,
    advanced=AdvancedOptions(log_level=1)
)
