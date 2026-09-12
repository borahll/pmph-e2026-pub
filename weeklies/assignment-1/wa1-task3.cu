#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>
#include <cuda_runtime.h>

#define GPU_RUNS 300
#define BLOCK_SIZE 256
#define EPSILON 0.000001f


// CPU sequential vector addition
void cpuVectorAdd(float *A, float *B, float *C, unsigned int N) {
    for (unsigned int i = 0; i < N; i++) {
        C[i] = A[i] + B[i];
    }
}


// GPU parallel vector addition
__global__ void vectorAddKernel(float *A, float *B, float *C, unsigned int N) {
    unsigned int gid = blockIdx.x * blockDim.x + threadIdx.x;

    if (gid < N) {
        C[gid] = A[gid] + B[gid];
    }
}


// Returns elapsed time in microseconds
double elapsedTime(struct timeval start, struct timeval end) {
    return (end.tv_sec - start.tv_sec) * 1000000.0 + (end.tv_usec - start.tv_usec);
}


int main(int argc, char **argv) {

    if (argc != 2) {
        printf("Incorrect usage\n", argv[0]);
        exit(1);
    }

    unsigned int N = atoi(argv[1]);
    printf("N is: %u\n", N);

    if (N == 0) {
        printf("N must be greater than 0.\n");
        exit(1);
    }

    cudaSetDevice(0);

    long double mem_size = N * sizeof(float);


    // Allocate host memory
    float *h_A = (float *) malloc(mem_size);
    float *h_B = (float *) malloc(mem_size);
    float *h_cpu = (float *) malloc(mem_size);
    float *h_gpu = (float *) malloc(mem_size);


    // Initialize input vectors
    for (unsigned int i = 0; i < N; i++) {
        h_A[i] = (float)i;
        h_B[i] = 2.0f * (float)i;
    }

    // CPU sequential execution - ONE RUN ONLY

    struct timeval cpu_start, cpu_end;

    gettimeofday(&cpu_start, NULL);

    cpuVectorAdd(h_A, h_B, h_cpu, N);

    gettimeofday(&cpu_end, NULL);

    double cpu_time = elapsedTime(cpu_start, cpu_end);

    // Allocate GPU memory

    float *d_A;
    float *d_B;
    float *d_C;

    cudaMalloc(&d_A, mem_size);
    cudaMalloc(&d_B, mem_size);
    cudaMalloc(&d_C, mem_size);

    // Cpy to GPU
    cudaMemcpy(d_A, h_A, mem_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, mem_size, cudaMemcpyHostToDevice);

    // Grid and block sizes

    unsigned int blocks = (N + BLOCK_SIZE - 1) / BLOCK_SIZE;

    printf("Block size: %d\n", BLOCK_SIZE);
    printf("Number of blocks: %u\n", blocks);

    // Warm-up kernel

    vectorAddKernel<<<blocks, BLOCK_SIZE>>>(d_A, d_B, d_C, N);
    cudaDeviceSynchronize();

    // GPU timing

    struct timeval gpu_start, gpu_end;

    gettimeofday(&gpu_start, NULL);

    for (int r = 0; r < GPU_RUNS; r++) {
        vectorAddKernel<<<blocks, BLOCK_SIZE>>>(d_A, d_B, d_C, N);
    }

    cudaDeviceSynchronize();

    gettimeofday(&gpu_end, NULL);

    // Average GPU kernel time in microseconds
    double gpu_time = elapsedTime(gpu_start, gpu_end) / GPU_RUNS;


    // Check kernel errors
    cudaError_t error = cudaGetLastError();

    if (error != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(error));
        exit(2);
    }

    // Copy GPU result back to CPU

    cudaMemcpy(h_gpu, d_C, mem_size, cudaMemcpyDeviceToHost);

    // Validation

    int valid = 1;

    for (unsigned int i = 0; i < N; i++) {

        if (fabs(h_cpu[i] - h_gpu[i]) >= EPSILON) {

            printf("Invalid result at index %u\n", i);
            printf("CPU: %f, GPU: %f\n", h_cpu[i], h_gpu[i]);

            valid = 0;
            break;
        }
    }

    if (valid)
        printf("VALID\n");
    else
        printf("INVALID\n");

    // Performance

    double gigabytespersec = (3.0 * N * sizeof(float)) / (gpu_time * 1000.0);

    double speedup = cpu_time / gpu_time;

    printf("CPU time: %f microseconds\n", cpu_time);
    printf("GPU time: %f microseconds\n", gpu_time);
    printf("Speed-up: %fx\n", speedup);
    printf("GPU mem. throughput: %f GB/sec\n", gigabytespersec);
    printf("Validation epsilon: %f\n", EPSILON);

    // Clean up
    free(h_A); free(h_B); free(h_cpu); free(h_gpu); cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);

    return 0;
}