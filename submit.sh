#!/bin/bash
# Demonstrator script to run multiple simulations per GPU with MPS on DGX-A100
#
# Alan Gray, NVIDIA
# Location of GROMACS binary
#GMX=/lustre/fsw/devtech/hpc-devtech/alang/gromacs-binaries/v2021.2_tmpi_cuda11.2/bin/gmx
# Location of input file
#INPUT=/lustre/fsw/devtech/hpc-devtech/alang/Gromacs_input/rnase.tpr
NGPU=1 # Number of GPUs in server
NCORE=16 # Number of CPU cores in server
NSIMPERGPU=1 # Number of simulations to run per GPU (with MPS)
# Number of threads per simulation
NTHREAD=$(($NCORE/($NGPU*$NSIMPERGPU)))
if [ $NTHREAD -eq 0 ]
then
    NTHREAD=1
fi
export OMP_NUM_THREADS=$NTHREAD
# Start MPS daemon
nvidia-cuda-mps-control -d
# Loop over number of GPUs in server
for (( i=0; i<$NGPU; i++ ));
do
    # Set a CPU NUMA specific to GPU in use with best affinity (specific to DGX-A100)
    case $i in
        0)NUMA=3;;
        1)NUMA=2;;
        2)NUMA=1;;
        3)NUMA=0;;
        4)NUMA=7;;
        5)NUMA=6;;
        6)NUMA=5;;
        7)NUMA=4;;
    esac
    # Loop over number of simulations per GPU
    for (( j=0; j<$NSIMPERGPU; j++ ));
    do
# Create a unique identifier for this simulation to use as a working directory
        id=gpu${i}_sim${j}
        rm -rf $id
        #mkdir -p $id
        #cd $id
#        cp md.tpr md_${id}.tpr
# Launch GROMACS in the background on the desired resources
        echo "Launching simulation $j on GPU $i with $NTHREAD CPU thread(s) on NUMA region $NUMA"
        CUDA_VISIBLE_DEVICES=$i 
        cp md.tpr md_${id}.tpr 
        gmx mdrun -update gpu -nsteps 100000 -maxh 0.2 -resethway -nstlist 100 -deffnm md_${id} -v >& mdrun_${id}.log &
        #cd ..
    done
done
echo "Waiting for simulations to complete..."
wait
