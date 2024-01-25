/*
    (C) Copyright 2015 CEA LIST. All Rights Reserved.
    Contributor(s): Olivier BICHLER (olivier.bichler@cea.fr)

    This software is governed by the CeCILL-C license under French law and
    abiding by the rules of distribution of free software.  You can  use,
    modify and/ or redistribute the software under the terms of the CeCILL-C
    license as circulated by CEA, CNRS and INRIA at the following URL
    "http://www.cecill.info".

    As a counterpart to the access to the source code and  rights to copy,
    modify and redistribute granted by the license, users are provided only
    with a limited warranty  and the software's author,  the holder of the
    economic rights,  and the successive licensors  have only  limited
    liability.

    The fact that you are presently reading this means that you have had
    knowledge of the CeCILL-C license and that you accept its terms.
*/

#ifndef N2D2_EXPORTC_TYPEDEFS_H
#define N2D2_EXPORTC_TYPEDEFS_H

#include "params.h"
#include <stdint.h>
// 定义激活函数的枚举类型
typedef enum {
    Logistic,
    LogisticWithLoss,
    FastSigmoid,
    Tanh,
    TanhLeCun,
    Saturation,
    Rectifier,// 整流器（ReLU）
    Linear,
    Softplus
} ActivationFunction_T;

// 定义池化类型的枚举
typedef enum {
    Max,// 最大池化
    Average//// 平均池化
} Pooling_T;

// 定义插值结构体
typedef struct {
    unsigned int lowIndex;// 低索引
    unsigned int highIndex;// 高索引
    float interpolation;// 插值
} Interpolation;

// 定义操作模式的枚举
typedef enum {
    Sum,// 求和
    Mult // 乘法
} OpMode_T;

// 定义系数模式的枚举
typedef enum {
    PerLayer,// 每层
    PerInput,// 每输入
    PerChannel// 每通道
} CoeffMode_T;

#if defined(HAS_AP_CINT) && NB_BITS > 0 && NB_BITS != 8 && NB_BITS != 16 \
    && NB_BITS != 32 && NB_BITS != 64
#define CONCAT(x, y) x##y
#define INT(x) CONCAT(int, x)
#define UINT(x) CONCAT(uint, x)

#define MULT_0_4 0
#define MULT_1_4 4
#define MULT_2_4 8
#define MULT_3_4 12
#define MULT_4_4 16
#define MULT_5_4 20
#define MULT_6_4 24
#define MULT_7_4 28
#define MULT_8_4 32
#define MULT_9_4 36
#define MULT_10_4 40
#define MULT_11_4 44
#define MULT_12_4 48
#define MULT_13_4 52
#define MULT_14_4 56
#define MULT_15_4 60
#define MULT_16_4 64
#define CONCAT_MULT(x, y) MULT_##x##_##y
#define MULT(x, y) CONCAT_MULT(x, y)

#include <ap_cint.h>

typedef INT(NB_BITS) DATA_T;
typedef UINT(NB_BITS) UDATA_T;
typedef INT(MULT(NB_BITS, 4)) SUM_T;
typedef SUM_T BDATA_T;
#else//根据NB_BITS的值来定义不同的数据类型
#if NB_BITS == -64
typedef double DATA_T;
typedef double UDATA_T;
typedef double SUM_T;
typedef SUM_T BDATA_T;
#elif NB_BITS == -32 || NB_BITS == -16
typedef float DATA_T;
typedef float UDATA_T;
typedef float SUM_T;
typedef SUM_T BDATA_T;
#elif NB_BITS > 0 && NB_BITS <= 8
typedef int8_t DATA_T;
typedef uint8_t UDATA_T;
typedef int32_t SUM_T;
typedef SUM_T BDATA_T;
#elif NB_BITS > 8 && NB_BITS <= 16
typedef int16_t DATA_T;
typedef uint16_t UDATA_T;
typedef int64_t SUM_T;
typedef SUM_T BDATA_T;
#elif NB_BITS > 16
typedef int32_t DATA_T;
typedef uint32_t UDATA_T;
typedef int64_t SUM_T;
typedef SUM_T BDATA_T;
#endif
#endif
// 定义权重数据类型
typedef DATA_T WDATA_T;
// 定义数据类型的最大最小值
#if NB_BITS < 0
#define DATA_T_MAX 1.0
#define DATA_T_MIN -1.0
#define UDATA_T_MAX 1.0
#define UDATA_T_MIN 0.0
#else
#define DATA_T_MAX ((1LL << (NB_BITS - 1)) - 1)
#define DATA_T_MIN (-(1LL << (NB_BITS - 1)))
#define UDATA_T_MAX ((1LL << NB_BITS) - 1)
#define UDATA_T_MIN 0LL
#endif

#endif // N2D2_EXPORTC_TYPEDEFS_H
