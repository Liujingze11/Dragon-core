#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "cpp_utils.h"
#include "env.h"
#include "Network.h"
#include "util.h"
//数负责读取输入数据（刺激）到 inputBuffer，
//并将期望的输出结果读取到 expectedOutputBuffer。
//它调用了一个名为 envRead() 的函数
// 读取输入刺激数据和期望的输出结果。
void readStimulus(
                  UDATA_T* inputBuffer,// 输入缓冲区，用于存储输入数据
                  Target_T* expectedOutputBuffer)// 期望输出缓冲区，用于存储期望的输出结果
{
    envRead(ENV_SIZE_Y*ENV_SIZE_X*ENV_NB_OUTPUTS,
            ENV_SIZE_Y, ENV_SIZE_X,
            (DATA_T*) inputBuffer, //TODO
            OUTPUTS_SIZE[0], expectedOutputBuffer);//读取图片，cpp_utils.h中的函数
}

// 处理输入数据并评估预测的准确性。
int processInput(        UDATA_T* inputBuffer,
                            Target_T* expectedOutputBuffer,
                            Target_T* predictedOutputBuffer,
			    UDATA_T* output_value)
{
    size_t nbPredictions = 0;// 计数器，用于统计总的预测次数
    size_t nbValidPredictions = 0;// 计数器，用于统计正确的预测次数

    propagate(inputBuffer, predictedOutputBuffer, output_value);

    // assert(expectedOutputBuffer.size() == predictedOutputBuffer.size());
    for(size_t i = 0; i < OUTPUTS_SIZE[0]; i++) {
        if (expectedOutputBuffer[i] >= 0) {
            ++nbPredictions;

            if(predictedOutputBuffer[i] == expectedOutputBuffer[i]) {
                ++nbValidPredictions;
            }
        }
    }

    return (nbPredictions > 0)
        ? nbValidPredictions : 0;
}


int main(int argc, char* argv[]) {

    // const N2D2::Network network{};
    size_t instret, cycles;// 定义指令和周期计数器变量

#if ENV_DATA_UNSIGNED // 根据环境配置定义输入缓冲区
    UDATA_T inputBuffer[ENV_SIZE_Y*ENV_SIZE_X*ENV_NB_OUTPUTS];
#else
    std::vector<DATA_T> inputBuffer(network.inputSize());
#endif
    // 定义期望输出和预测输出的缓冲区
    Target_T expectedOutputBuffer[OUTPUTS_SIZE[0]];
    Target_T predictedOutputBuffer[OUTPUTS_SIZE[0]];
    UDATA_T output_value;
    // 读取并存储当前指令和周期计数器的值
    readStimulus(inputBuffer, expectedOutputBuffer);
    instret = -read_csr(minstret);// 读取指令计数器的当前值并取反
    cycles = -read_csr(mcycle);// 读取周期计数器的当前值并取反
    const int success = processInput(inputBuffer, 
                                                        expectedOutputBuffer, 
                                                        predictedOutputBuffer,
							&output_value);
    instret += read_csr(minstret);// 读取新的指令计数器的值并加到之前的值上
    cycles += read_csr(mcycle);// 读取新的周期计数器的值并加到之前的值上
    
    printf("Expected  = %d\n", expectedOutputBuffer[0]);
    printf("Predicted = %d\n", predictedOutputBuffer[0]);
    printf("Result : %d/1\n", success);
    printf("credence: %d\n", output_value);
    printf("image %s: %d instructions\n", stringify(MNIST_INPUT_IMAGE), (int)(instret));
    //指令数
    printf("image %s: %d cycles\n", stringify(MNIST_INPUT_IMAGE), (int)(cycles));
    //周期数
#ifdef OUTPUTFILE
    FILE *f = fopen("success_rate.txt", "w");
    if (f == NULL) {
        N2D2_THROW_OR_ABORT(std::runtime_error,
            "Could not create file:  success_rate.txt");
    }
    fprintf(f, "%f", successRate);
    fclose(f);
#endif
}
