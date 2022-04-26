#!/bin/bash

set -e
set -x

mkdir cpp/build
pushd cpp/build

EXTRA_CMAKE_ARGS=""

# Include g++'s system headers
if [ "$(uname)" == "Linux" ]; then
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

if [[ "${target_platform}" == "osx-arm64" ]]; then
    # We need llvm 11+ support in Arrow for this
    EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=OFF"
    sed -ie "s;protoc-gen-grpc.*$;protoc-gen-grpc=${BUILD_PREFIX}/bin/grpc_cpp_plugin\";g" ../src/arrow/flight/CMakeLists.txt
    sed -ie 's;"--with-jemalloc-prefix\=je_arrow_";"--with-jemalloc-prefix\=je_arrow_" "--with-lg-page\=14";g' ../cmake_modules/ThirdpartyToolchain.cmake
else
    EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=ON"
fi

if [[ "${target_platform}" == osx-* ]]; then
   EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DCMAKE_CXX_STANDARD=14"
else
   EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
fi

cmake \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DARROW_DATASET=ON \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_FLIGHT=ON \
    -DARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS=ON \
    -DARROW_HDFS=ON \
    -DARROW_GCS=ON \
    -DARROW_JEMALLOC=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_ORC=ON \
    -DARROW_PACKAGE_PREFIX=$PREFIX \
    -DARROW_PARQUET=ON \
    -DARROW_PLASMA=ON \
    -DARROW_PYTHON=ON \
    -DARROW_S3=ON \
    -DARROW_SIMD_LEVEL=NONE \
    -DARROW_USE_LD_GOLD=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DLLVM_TOOLS_BINARY_DIR=$PREFIX/bin \
    -DPython3_EXECUTABLE=${PYTHON} \
    -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc \
    -GNinja \
    ${EXTRA_CMAKE_ARGS} \
    ..

# Commented out until jemalloc and mimalloc are fixed upstream
if [[ "${target_platform}" == "osx-arm64" ]]; then
     ninja jemalloc_ep-prefix/src/jemalloc_ep-stamp/jemalloc_ep-patch mimalloc_ep-prefix/src/mimalloc_ep-stamp/mimalloc_ep-patch
     cp $BUILD_PREFIX/share/gnuconfig/config.* jemalloc_ep-prefix/src/jemalloc_ep/build-aux/
     sed -ie 's/list(APPEND mi_cflags -march=native)//g' mimalloc_ep-prefix/src/mimalloc_ep/CMakeLists.txt
     # Use the correct register for thread-local storage
     sed -ie 's/tpidr_el0/tpidrro_el0/g' mimalloc_ep-prefix/src/mimalloc_ep/include/mimalloc-internal.h
fi

# Limit number of threads used to avoid hardware oversubscription
EXTRA_NINJA_ARGS=""
if [[ "${target_platform}" == "linux-aarch64" ]] || [[ "${target_platform}" == "linux-ppc64le" ]]; then
     EXTRA_NINJA_ARGS="${EXTRA_NINJA_ARGS} -j 4"
fi


ninja install ${EXTRA_NINJA_ARGS}

popd
