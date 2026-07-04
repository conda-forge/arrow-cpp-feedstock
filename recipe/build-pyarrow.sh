#!/bin/sh
set -ex

# Build dependencies
export ARROW_HOME=$PREFIX
export PARQUET_HOME=$PREFIX
export SETUPTOOLS_SCM_PRETEND_VERSION=$PKG_VERSION
export PYARROW_WITH_ACERO=1
export PYARROW_WITH_AZURE=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
export PYARROW_WITH_GANDIVA=1
export PYARROW_WITH_GCS=1
export PYARROW_WITH_HDFS=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PARQUET_ENCRYPTION=1
export PYARROW_WITH_S3=1
export PYARROW_WITH_SUBSTRAIT=1
export CMAKE_GENERATOR=Ninja
BUILD_EXT_FLAGS=""

# Enable CUDA support
if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" != "None" ]]; then
    export PYARROW_WITH_CUDA=1
    if [[ "${build_platform}" != "${target_platform}" ]]; then
        export CUDA_TOOLKIT_ROOT_DIR="${PREFIX}"
    fi
else
    export PYARROW_WITH_CUDA=0
fi

# Resolve: Make Error at cmake_modules/SetupCxxFlags.cmake:338 (message): Unsupported arch flag: -march=.
if [[ "${target_platform}" == "linux-aarch64" ]]; then
    export PYARROW_CMAKE_OPTIONS="-DARROW_ARMV8_ARCH=armv8-a ${PYARROW_CMAKE_OPTIONS}"
fi

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "${target_platform}" == "linux-aarch64" ]] || [[ "${target_platform}" == "linux-ppc64le" ]]; then
    # Limit number of threads used to avoid hardware oversubscription
    export CMAKE_BUILD_PARALLEL_LEVEL=4
fi

cd python

python -m pip install . -vv \
    -C build.verbose=true \
    -C cmake.build-type=release \
    -C cmake.args="-DARROW_SIMD_LEVEL=NONE" \
    -C cmake.args=${PYARROW_CMAKE_OPTIONS}

if [[ "$PKG_NAME" != "pyarrow-tests" ]]; then
    if [[ "$is_freethreading" == "true" ]]; then
        # work around https://github.com/conda/conda-build/issues/5563
        rm -r $PREFIX/lib/python3.14t/site-packages/pyarrow/tests
    else
        rm -r ${SP_DIR}/pyarrow/tests
    fi
fi

cd ..
