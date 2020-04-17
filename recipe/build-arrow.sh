#!/bin/bash

set -e
set -x

mkdir cpp/build
pushd cpp/build

EXTRA_CMAKE_ARGS=""

if [ "$(uname -m)" = "ppc64le" ] || [ "$(uname -m)" = "aarch64" ]; then
  ARROW_GANDIVA=OFF
else
  ARROW_GANDIVA=ON
fi

# Include g++'s system headers
if [[ "$(uname)" == "Linux" ]]
then
  SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
  EXTRA_CMAKE_ARGS=" -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"
fi

# Enable CUDA support
if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" != "None" ]]
then
    if [[ -z "${CUDA_HOME+x}" ]]
    then
        echo "cuda_compiler_version=${cuda_compiler_version} CUDA_HOME=$CUDA_HOME"
        CUDA_GDB_EXECUTABLE=$(which cuda-gdb || exit 0)
        if [[ -n "$CUDA_GDB_EXECUTABLE" ]]
        then
            CUDA_HOME=$(dirname $(dirname $CUDA_GDB_EXECUTABLE))
        else
            echo "Cannot determine CUDA_HOME: cuda-gdb not in PATH"
            return 1
        fi
    fi
    EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=ON -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} -DCMAKE_LIBRARY_PATH=${CUDA_HOME}/lib64/stubs"
else
    EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=OFF"
fi

cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DLLVM_TOOLS_BINARY_DIR=$PREFIX/bin \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_PACKAGE_PREFIX=$PREFIX \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_SSE42=OFF \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_JEMALLOC=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_DATASET=ON \
    -DARROW_FLIGHT=ON \
    -DARROW_PLASMA=ON \
    -DARROW_PYTHON=ON \
    -DARROW_PARQUET=ON \
    -DARROW_GANDIVA=${ARROW_GANDIVA} \
    -DARROW_HDFS=ON \
    -DARROW_ORC=ON \
    -DARROW_S3=ON \
    -DCMAKE_AR=${AR} \
    -DCMAKE_RANLIB=${RANLIB} \
    -GNinja \
    ${EXTRA_CMAKE_ARGS} \
    ..
if [ "$(uname -m)" = "ppc64le" ]; then
    # Decrease parallelism a bit as we will otherwise get out-of-memory problems
    echo "Using $(grep -c ^processor /proc/cpuinfo) CPUs"
    CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
    CPU_COUNT=$((CPU_COUNT / 4))
    ninja install -j${CPU_COUNT}
else
    ninja install
fi

popd
