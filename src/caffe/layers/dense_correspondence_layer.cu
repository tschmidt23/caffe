#include "caffe/layers/dense_correspondence_layer_impl.hpp"

namespace caffe {

template <typename Dtype,
          template <typename> class LossFunctorT>
__global__ void DCLBackwardPositives(const int N,
                                     const int width,
                                     const int height,
                                     const int channels,
                                     const Dtype * posDiffData,
                                     const Dtype * posSampleAData,
                                     const Dtype * posSampleBData,
                                     const Dtype posAlpha,
                                     const LossFunctorT<Dtype> lossFunctor,
                                     Dtype * gradA,
                                     Dtype * gradB) {

    CUDA_KERNEL_LOOP(i, N) {

        const int uA = floor(posSampleAData[0 + 2*i] + 0.5);
        const int vA = floor(posSampleAData[1 + 2*i] + 0.5);
        const Dtype uB = posSampleBData[0 + 2*i];
        const Dtype vB = posSampleBData[1 + 2*i];

        const Dtype * thisDiff = posDiffData + i*channels;

        lossFunctor.template differentiateLoss<CudaAtomicAddition>(thisDiff,width,height,channels,
                                                                   uA,vA,posAlpha,gradA);

        lossFunctor.template differentiateLoss<CudaAtomicAddition>(thisDiff,width,height,channels,
                                                                   uB,vB,-posAlpha,gradB);

    }

}

//template __global__ void DCLBackwardPositives<float, SquaredLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const SquaredLossFunctor<float>,float *, float *);
//template __global__ void DCLBackwardPositives<float, HuberLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const HuberLossFunctor<float>,float *, float *);


template <typename Dtype,
          template <typename> class LossFunctorT>
__global__ void DCLBackwardNegatives(const int N,
                                     const int width,
                                     const int height,
                                     const int channels,
                                     const Dtype * negDiffData,
                                     const Dtype * negSampleAData,
                                     const Dtype * negSampleBData,
                                     const Dtype negAlpha,
                                     const LossFunctorT<Dtype> lossFunctor,
                                     Dtype * gradA,
                                     Dtype * gradB) {

    CUDA_KERNEL_LOOP(i, N) {

        const int uA = floor(negSampleAData[0 + 2*i] + 0.5);
        const int vA = floor(negSampleAData[1 + 2*i] + 0.5);
        const int uB = floor(negSampleBData[0 + 2*i] + 0.5);
        const int vB = floor(negSampleBData[1 + 2*i] + 0.5);

        const Dtype * thisDiff = negDiffData + i*channels;

        lossFunctor.template differentiateLoss<CudaAtomicAddition>(thisDiff,width,height,channels,
                                                                   uA,vA,negAlpha,gradA);

        lossFunctor.template differentiateLoss<CudaAtomicAddition>(thisDiff,width,height,channels,
                                                                   uB,vB,-negAlpha,gradB);

    }

}

//template __global__ void DCLBackwardNegatives<float, HingeLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const HingeLossFunctor<float>,float *, float *);
//template __global__ void DCLBackwardNegatives<float, HuberHingeLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const HuberHingeLossFunctor<float>,float *, float *);
//template __global__ void DCLBackwardNegatives<float, NegativeExponentialLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const NegativeExponentialLossFunctor<float>,float *, float *);

template <typename Dtype,
          template <typename> class LossFunctorT>
void backwardPositiveWrapper(const int N,
                             const int width,
                             const int height,
                             const int channels,
                             const Dtype * posDiffData,
                             const Dtype * posSampleAData,
                             const Dtype * posSampleBData,
                             const Dtype posAlpha,
                             const LossFunctorT<Dtype> lossFunctor,
                             Dtype * gradA,
                             Dtype * gradB) {

    if (N == 0) { return; }

    DCLBackwardPositives<<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
        N, width, height, channels, posDiffData, posSampleAData, posSampleBData,
        posAlpha, lossFunctor, gradA, gradB);
    CUDA_POST_KERNEL_CHECK;

}

template void backwardPositiveWrapper<float, SquaredLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const SquaredLossFunctor<float>,float *, float *);
template void backwardPositiveWrapper<float, HuberLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const HuberLossFunctor<float>,float *, float *);
template void backwardPositiveWrapper<float, TukeyLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const TukeyLossFunctor<float>,float *, float *);

template void backwardPositiveWrapper<double, SquaredLossFunctor>(const int, const int, const int, const int, const double *, const double *, const double *, const double, const SquaredLossFunctor<double>,double *, double *);
template void backwardPositiveWrapper<double, HuberLossFunctor>(const int, const int, const int, const int, const double *, const double *, const double *, const double, const HuberLossFunctor<double>,double *, double *);
template void backwardPositiveWrapper<double, TukeyLossFunctor>(const int, const int, const int, const int, const double *, const double *, const double *, const double, const TukeyLossFunctor<double>,double *, double *);


template <typename Dtype,
          template <typename> class LossFunctorT>
void backwardNegativeWrapper(const int N,
                             const int width,
                             const int height,
                             const int channels,
                             const Dtype * negDiffData,
                             const Dtype * negSampleAData,
                             const Dtype * negSampleBData,
                             const Dtype negAlpha,
                             const LossFunctorT<Dtype> lossFunctor,
                             Dtype * gradA,
                             Dtype * gradB) {

    if (N == 0) { return; }

    DCLBackwardPositives<<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
        N, width, height, channels, negDiffData, negSampleAData, negSampleBData,
        negAlpha, lossFunctor, gradA, gradB);
    CUDA_POST_KERNEL_CHECK;

}

template void backwardNegativeWrapper<float, HingeLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const HingeLossFunctor<float>,float *, float *);
template void backwardNegativeWrapper<float, HuberHingeLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const HuberHingeLossFunctor<float>,float *, float *);
template void backwardNegativeWrapper<float, NegativeExponentialLossFunctor>(const int, const int, const int, const int, const float *, const float *, const float *, const float, const NegativeExponentialLossFunctor<float>,float *, float *);

template void backwardNegativeWrapper<double, HingeLossFunctor>(const int, const int, const int, const int, const double *, const double *, const double *, const double, const HingeLossFunctor<double>,double *, double *);
template void backwardNegativeWrapper<double, HuberHingeLossFunctor>(const int, const int, const int, const int, const double *, const double *, const double *, const double, const HuberHingeLossFunctor<double>,double *, double *);
template void backwardNegativeWrapper<double, NegativeExponentialLossFunctor>(const int, const int, const int, const int, const double *, const double *, const double *, const double, const NegativeExponentialLossFunctor<double>,double *, double *);



} // namespace caffe