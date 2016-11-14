import glob

from lobster.core import AdvancedOptions, Category, Config, StorageConfiguration, Workflow
from lobster.core import ParentDataset, ProductionDataset

version = 'v0'

storage = StorageConfiguration(
    output=[
        "hdfs://eddie.crc.nd.edu:19000/store/user/matze/ttH/fastsim_" + version,
        "file:///hadoop/store/user/matze/ttH/fastsim_" + version,
        "root://deepthought.crc.nd.edu//store/user/matze/ttH/fastsim_" + version,
        "chirp://eddie.crc.nd.edu:9094/store/user/matze/ttH/fastsim_" + version,
        "gsiftp://T3_US_NotreDame/store/user/matze/ttH/fastsim_" + version,
        "srm://T3_US_NotreDame/store/user/matze/ttH/fastsim_" + version,
    ]
)

datasets = [s.replace('_aod.py', '') for s in glob.glob('*_aod.py') if 'filtered' not in s]
workflows = []

for dset in datasets:
    aod = Workflow(
        label=dset + '_AOD',
        pset=dset + '_aod.py',
        dataset=ProductionDataset(
            events_per_task=1000,
            events_per_lumi=1000,
            number_of_tasks=1000
        ),
        category=Category(
            name='aod',
            cores=1,
            memory=2000
        )
    )

    maod = Workflow(
        label=dset + '_MiniAOD',
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
            memory=2000,
            runtime=45 * 60
        )
    )

    workflows.extend([aod, maod])

config = Config(
    workdir='/tmpscratch/users/matze/ttH/fastsim_' + version,
    plotdir='~/www/lobster/ttH/fastsim_' + version,
    storage=storage,
    workflows=workflows,
    advanced=AdvancedOptions(log_level=1)
)
