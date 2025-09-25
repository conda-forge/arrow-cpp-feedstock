#!/bin/bash
set -ex

mkdir -p cpp/build
pushd cpp/build

# Include g++'s system headers
if [ "$(uname)" == "Linux" ]; then
  SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
  ARROW_GANDIVA_PC_CXX_FLAGS="${SYSTEM_INCLUDES}"
else
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
  ARROW_GANDIVA_PC_CXX_FLAGS="-D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Enable CUDA support
if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" != "None" ]]
then
    CMAKE_ARGS="${CMAKE_ARGS} -DARROW_CUDA=ON -DCUDAToolkit_ROOT=${CUDA_HOME} -DCMAKE_LIBRARY_PATH=${CONDA_BUILD_SYSROOT}/lib"
else
    CMAKE_ARGS="${CMAKE_ARGS} -DARROW_CUDA=OFF"
fi

if [[ "${build_platform}" != "${target_platform}" ]]; then
    # point to a usable protoc/grpc_cpp_plugin if we're cross-compiling
    CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
    if [[ ! -f ${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang ]]; then
        ln -sf ${BUILD_PREFIX}/bin/clang ${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang
    fi
    CMAKE_ARGS="${CMAKE_ARGS} -DCLANG_EXECUTABLE=${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang"
    CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_LINK_EXECUTABLE=${BUILD_PREFIX}/bin/llvm-link"
    CMAKE_ARGS="${CMAKE_ARGS} -DARROW_JEMALLOC_LG_PAGE=16"
    CMAKE_ARGS="${CMAKE_ARGS} -DARROW_GRPC_CPP_PLUGIN=${BUILD_PREFIX}/bin/grpc_cpp_plugin"
fi

# disable -fno-plt, which causes problems with GCC on PPC
if [[ "$target_platform" == "linux-ppc64le" ]]; then
  CFLAGS="$(echo $CFLAGS | sed 's/-fno-plt //g')"
  CXXFLAGS="$(echo $CXXFLAGS | sed 's/-fno-plt //g')"
fi

if [[ "${target_platform}" == "linux-aarch64" ]] || [[ "${target_platform}" == "linux-ppc64le" ]]; then
    # Limit number of threads used to avoid hardware oversubscription
    export CMAKE_BUILD_PARALLEL_LEVEL=3
fi

# IPO produces segfaults in the test suite on macOS x86-64
if [[ "$target_platform" == "osx-64" ]]; then
    CMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
else
    CMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
fi

# reusable variable for dependencies we cannot yet unvendor
export READ_RECIPE_META_YAML_WHY_NOT=OFF

# for available switches see
# https://github.com/apache/arrow/blame/apache-arrow-12.0.0/cpp/cmake_modules/DefineOptions.cmake
# placeholder in ARROW_GDB_INSTALL_DIR must match _la_placeholder in activate.sh
cmake -GNinja \
    -DARROW_ACERO=ON \
    -DARROW_AZURE=ON \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BUILD_TESTS=ON \
    -DARROW_BUILD_UTILITIES=ON \
    -DARROW_COMPUTE=ON \
    -DARROW_CSV=ON \
    -DARROW_CXXFLAGS="${CXXFLAGS}" \
    -DARROW_DATASET=ON \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_ENABLE_TIMING_TESTS=OFF \
    -DARROW_FILESYSTEM=ON \
    -DARROW_FLIGHT=ON \
    -DARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS=ON \
    -DARROW_FLIGHT_SQL=ON \
    -DARROW_GANDIVA=ON \
    -DARROW_GANDIVA_PC_CXX_FLAGS="${ARROW_GANDIVA_PC_CXX_FLAGS}" \
    -DARROW_GCS=ON \
    -DARROW_GDB_INSTALL_DIR=replace_this_section_with_absolute_slashed_path_to_CONDA_PREFIX/lib \
    -DARROW_HDFS=ON \
    -DARROW_JEMALLOC=ON \
    -DARROW_JSON=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_ORC=ON \
    -DARROW_PACKAGE_PREFIX=$PREFIX \
    -DARROW_PARQUET=ON \
    -DPARQUET_BUILD_EXECUTABLES=ON \
    -DPARQUET_REQUIRE_ENCRYPTION=ON \
    -DARROW_S3=ON \
    -DARROW_SIMD_LEVEL=NONE \
    -DARROW_SUBSTRAIT=ON \
    -DARROW_USE_GLOG=ON \
    -DARROW_USE_LD_GOLD=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_NLOHMANN_JSON=ON \
    -DARROW_WITH_OPENTELEMETRY=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_UCX=OFF \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION:BOOL=${CMAKE_INTERPROCEDURAL_OPTIMIZATION} \
    -DLLVM_TOOLS_BINARY_DIR=$PREFIX/bin \
    -DZSTD_HOME=${PREFIX} \
    -DZSTD_INCLUDE_DIR=${PREFIX}/include \
    -DZSTD_LIBRARY=${PREFIX}/lib/libzstd${SHLIB_EXT} \
    -DMAKE=$BUILD_PREFIX/bin/make \
    -DPython3_EXECUTABLE=${PYTHON} \
    ${CMAKE_ARGS} \
    ..

# Do not install arrow, only build.
cmake --build . --config Release

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != 1 && "$cuda_compiler_version" == "None" ]]; then
    npm install -g azurite
    export ARROW_TEST_DATA=$SRC_DIR/testing/data
    export PARQUET_TEST_DATA=$SRC_DIR/cpp/submodules/parquet-testing/data
    ctest --progress --output-on-failure
fi

popd
