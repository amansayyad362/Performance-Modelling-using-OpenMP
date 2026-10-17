#!/usr/bin/bash -l
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --job-name=ptfscam
#SBATCH --output=jobscript_results/ptfscam.out
#SBATCH --export=NONE
#SBATCH -C hwperf

unset SLURM_EXPORT_ENV

# Load modules
module load intel
module load likwid
CXX=icpx make

# Define grid sizes
grid_sizes=(
    "2000 20000"
    "20000 2000"
    "1000 400000"
)

for size in "${grid_sizes[@]}"; do

    read Ny Nx <<< "$size"
    # ============================
    # Run with 1ccNUMA (18 cores)
    # ============================

    log_file="jobscript_results/ptfscam_Ny${Ny}-Nx${Nx}-1ccNUMA.txt"
    > "$log_file"
    echo "Running Ny=$Ny, Nx=$Nx, 1ccNUMA" >> "$log_file"
    export OMP_NUM_THREADS=18
    export OMP_PROC_BIND=close
    export OMP_PLACES=cores

    srun ./test >> "$log_file" 2>&1

    likwid-perfctr -C 0-17 -g FLOPS_DP -m \
        srun --cpu-freq=2200000-2200000:performance --mem-bind=local ./perf $Ny $Nx >> "$log_file" 2>&1

    # ============================
    # Run with 4ccNUMA (72 cores)
    # ============================


    log_file="jobscript_results/ptfscam_Ny${Ny}-Nx${Nx}-4ccNUMA.txt"
    > "$log_file"
    echo "Running Ny=$Ny, Nx=$Nx, 4ccNUMA" >> "$log_file"
    export OMP_NUM_THREADS=72   
    export OMP_PROC_BIND=spread
    export OMP_PLACES=cores
    srun ./test >> "$log_file" 2>&1

    likwid-perfctr -C 0-71 -g FLOPS_DP -m \
        srun --cpu-freq=2200000-2200000:performance --mem-bind=local ./perf $Ny $Nx >> "$log_file" 2>&1

done 

echo "All runs completed."




