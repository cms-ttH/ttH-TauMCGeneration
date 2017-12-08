set -e
set -x

das=1
setup=1

usage() { echo "usage: $0 [-ds]"; exit 1; }

while getopts "ds" o; do
   case "${o}" in
      d)
         das=0
         ;;
      s)
         setup=0
         ;;
      *)
         usage
         ;;
   esac
done

## Moriond 2018 LHE
era=Run2_2017
release=CMSSW_9_3_4
globaltag=93X_mc2017_realistic_v3
beamspot=Realistic25ns13TeVEarly2017Collision


declare -A setups

setups[ttH]=HIG-RunIIFall17wmLHEGS-00044-fragment.py
# setups[ttjets_dl]=TOP-RunIIFall17wmLHEGS-00001-fragment.py
# setups[ttjets_sl]=TOP-RunIIFall17wmLHEGS-00002-fragment.py
# setups[ttW]=HIG-RunIIFall17wmLHEGS-00040-fragment.py
# setups[ttWW]=TOP-RunIIFall17wmLHEGS-00066-fragment.py
# setups[ttZ]=HIG-RunIIFall17wmLHEGS-00041-fragment.py
# setups[WZ]=SMP-RunIIFall17wmLHEGS-00003-fragment.py

Init_proxy()
{
    voms-proxy-info -exists
    if [ $das -eq 1 -a $? -eq 1 ]; then
        echo "need a valid proxy"
        exit 1
    fi
}

Init_CMSSW()
{
    if [ $setup -eq 1 ]; then
        scram p CMSSW $release
        cd $release/src
        eval `scram runtime -sh`
    fi
}

Get_fragments()
{
    for cfgs in "${setups[@]}"; do
        for cfg in $cfgs; do
            if [[ $cfg =~ fragment ]]; then
                fn=${cfg##*/}
                frag=${fn%-fragment.py}
                cfg=${cfg//-/_}
                remote_path="--insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/"
                remote_path=${remote_path}${frag}
            else
                remote_path="https://raw.githubusercontent.com/cms-sw/genproductions/6c354c4e733ae957afffe0a8a73ec13435cfd8a3/"
                remote_path=${remote_path}${cfg}
            fi
            curl -s ${remote_path} \
                --retry 2 \
                --create-dirs \
                -o Configuration/GenProduction/$cfg
        done
    done
}

Copy_fragments()
{
    # Existence of ttH/TauMCGeneration is imposed
    if [ $setup -eq 1 ]; then
        cp -r ttH/TauMCGeneration/Configuration .
        scram b
    fi
}

Get_repo()
{
    if [ $setup -eq 1 ]; then
        git clone https://github.com/cms-ttH/ttH-TauMCGeneration.git \
            ttH/TauMCGeneration
        eval `scram runtime -sh`
        scram b
    fi
}

Run_AOD_in_2steps_1()
{
    sample=$1
    config=$2

    cmsDriver.py Configuration/GenProduction/python/${config} \
        -n 100 \
        --python_filename ${sample}_lhe.py \
        --fileout file:${sample}_lhe.root \
        --mc \
        --eventcontent LHE \
        --datatier LHE \
        --fast \
        --conditions ${globaltag} \
        --beamspot ${beamspot} \
        --step LHE \
        --era $era \
        --no_exec
}

Make_cfgs()
{
    sample=$1
    config=$2

#     if [[ $sample =~ ttW || $sample =~ ttZ || $sample =~ WZ ]]; then
#         Run_AOD_in_1step "${sample}" "${config}" "${filter}"
    # LHE
    Run_AOD_in_2steps_1 "${sample}" "${config}"
}

#
# Execute
#
#Init_proxy
Init_CMSSW
Get_repo
Copy_fragments
#Get_fragments

for smpl in "${!setups[@]}"; do
    cfg="${setups[$smpl]}"

    Make_cfgs "${smpl}" "${cfg}"
done
