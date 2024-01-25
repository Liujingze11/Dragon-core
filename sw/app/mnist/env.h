// N2D2 auto-generated file.
// @ Fri Sep 10 16:23:21 2021

#ifndef N2D2_EXPORTCPP_ENV_LAYER_H
#define N2D2_EXPORTCPP_ENV_LAYER_H

#include <stdint.h>
// 定义一个特殊的预处理器指令，用于选择输入图像（环境）
#define CHOOSE_INPUT_IMAGE 3 //一个特殊的定义符号，定义了图像3号

#define NO_EXCEPT
// 根据CHOOSE_INPUT_IMAGE的值来定义MNIST_INPUT_IMAGE
#if CHOOSE_INPUT_IMAGE == 3
#define MNIST_INPUT_IMAGE env0003 
//MNIST_INPUT_IMAGE 将被定义为 env0003
#elif CHOOSE_INPUT_IMAGE == 4618
#define MNIST_INPUT_IMAGE env4618
//MNIST_INPUT_IMAGE 将被定义为 env4618
#else
#error You need to choose your input image : CHOOSE_INPUT_IMAGE
#endif
//定义输入
#define ENV_SIZE_X 24 //输入图片宽度
#define ENV_SIZE_Y 24 //输入图片长度
#define ENV_NB_OUTPUTS 1 //通道数

#define ENV_DATA_UNSIGNED 1

#define ENV_OUTPUTS_SIZE (ENV_NB_OUTPUTS*ENV_SIZE_X*ENV_SIZE_Y)// 计算输出数据的大小

#define NETWORK_TARGETS 1
//Output targets network dimension definition:
// 定义输出目标网络的维度
static unsigned int OUTPUTS_HEIGHT[NETWORK_TARGETS] = {1};//输出图像高度
static unsigned int OUTPUTS_WIDTH[NETWORK_TARGETS] = {1};//输出图像宽度
static unsigned int NB_OUTPUTS[NETWORK_TARGETS] = {10};//输出通道数
static unsigned int NB_TARGET[NETWORK_TARGETS] = {10};//
static unsigned int OUTPUTS_SIZE[NETWORK_TARGETS] = {1};
typedef int32_t Target_0_T;
typedef Target_0_T Target_T;
#endif // N2D2_EXPORTCPP_ENV_LAYER_H
