function t --wraps='mpicc gemm_mpi.c src/base.c && mpirun -np 8 a.out' --description 'alias t mpicc gemm_mpi.c src/base.c && mpirun -np 8 a.out'
    mpicc gemm_mpi.c src/base.c && mpirun -np 8 a.out $argv
end
