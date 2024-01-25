#ifndef N2D2_NETWORK_HPP
#define N2D2_NETWORK_HPP

#include "typedefs.h"
#include "env.h"
// 声明一个函数，用于神经网络的前向传播
void propagate(const UDATA_T* inputs, Target_T* outputs, UDATA_T* maxPropagate_val);

#endif
