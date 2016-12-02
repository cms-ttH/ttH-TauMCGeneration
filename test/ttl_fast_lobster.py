from lobster.core import AdvancedOptions, Category, Config, StorageConfiguration, Workflow
from lobster.core import ParentDataset, ProductionDataset

version = 'v4'

storage = StorageConfiguration(
    output=[
        "hdfs://eddie.crc.nd.edu:19000/store/user/matze/ttH/fastsim_" + version,
        "file:///hadoop/store/user/matze/ttH/fastsim_" + version,
        "root://deepthought.crc.nd.edu//store/user/matze/ttH/fastsim_" + version,
        "gsiftp://T3_US_NotreDame/store/user/matze/ttH/fastsim_" + version,
        "chirp://eddie.crc.nd.edu:9094/store/user/matze/ttH/fastsim_" + version,
        "srm://T3_US_NotreDame/store/user/matze/ttH/fastsim_" + version,
    ]
)

datasets = ['fast_ttH']  # , 'fast_ttjets_sl']
workflows = []

for dset in datasets:
    lhe = Workflow(
        label=dset.replace('fast_', '') + '_lhe',
        pset=dset + '_lhe.py',
        dataset=ProductionDataset(
            events_per_task=1000,
            events_per_lumi=200,
            number_of_tasks=100
        ),
        category=Category(
            name='lhe',
            cores=1,
            disk=2000,
            memory=2000
        )
    )

    aod = Workflow(
        label=dset.replace('fast_', '') + '_aod',
        pset=dset + '_aod.py',
        dataset=ParentDataset(
            parent=lhe,
            units_per_task=10
        ),
        category=Category(
            name='aod',
            cores=1,
            disk=1000,
            memory=2000,
            runtime=90 * 60
        )
    )

    maod = Workflow(
        label=dset.replace('fast_', '') + '_maod',
        pset=dset + '_maod.py',
        merge_size='2000M',
        cleanup_input=True,
        dataset=ParentDataset(
            parent=aod,
            units_per_task=100
        ),
        category=Category(
            name='maod',
            cores=1,
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
