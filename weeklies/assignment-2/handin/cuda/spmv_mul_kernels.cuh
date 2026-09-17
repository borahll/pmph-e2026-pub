#ifndef SPMV_MUL_KERNELS
#define SPMV_MUL_KERNELS

__global__ void
replicate0(int tot_size, char* flags_d) {
    int index = blockDim.x*blockIdx.x + threadIdx.x;
    if(index < tot_size){
        flags_d[index] = 0;
    }
}

__global__ void
mkFlags(int mat_rows, int* mat_shp_sc_d, char* flags_d) {
//mkFlags<<< num_blocks_shp, block_size >>> ( mat_rows, mat_shp_sc_d, flags_d );
    int index = blockDim.x*blockIdx.x + threadIdx.x;
    if(index == 0){
        flags_d[0] = 1;
    }
    else if(index < mat_rows){
        flags_d[mat_shp_sc_d[index - 1]] = 1; 
    }
}

__global__ void
mult_pairs(int* mat_inds, float* mat_vals, float* vct, int tot_size, float* tmp_pairs) {
    int index = blockDim.x*blockIdx.x + threadIdx.x;
    if(index < tot_size){
        tmp_pairs[index] = vct[mat_inds[index]] * mat_vals[index];
    }
}

__global__ void
select_last_in_sgm(int mat_rows, int* mat_shp_sc_d, float* tmp_scan, float* res_vct_d) {
    int index = blockDim.x*blockIdx.x + threadIdx.x;
    if(index < mat_rows){
        res_vct_d[index] = tmp_scan[mat_shp_sc_d[index]-1];
    }
}

#endif // SPMV_MUL_KERNELS
