@echo on

mkdir "%SRC_DIR%"\cpp\build
pushd "%SRC_DIR%"\cpp\build

:: Enable CUDA support
if "%cuda_compiler_version%"=="None" (
    set "EXTRA_CMAKE_ARGS=-DARROW_CUDA=OFF"
) else (
    REM this should move to nvcc-feedstock
    set "CUDA_PATH=%CUDA_PATH:\=/%"
    set "CUDA_HOME=%CUDA_HOME:\=/%"

    set "EXTRA_CMAKE_ARGS=-DARROW_CUDA=ON"
)

cmake -G "Ninja" ^
      -DARROW_DEPENDENCY_SOURCE=SYSTEM ^
      -DARROW_PACKAGE_PREFIX="%LIBRARY_PREFIX%" ^
      -DARROW_BOOST_USE_SHARED:BOOL=ON ^
      -DARROW_BUILD_TESTS:BOOL=OFF ^
      -DARROW_BUILD_UTILITIES:BOOL=OFF ^
      -DARROW_BUILD_STATIC:BOOL=OFF ^
      -DARROW_DATASET:BOOL=ON ^
      -DARROW_FLIGHT:BOOL=ON ^
      -DARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS:BOOL=ON ^
      -DARROW_GANDIVA:BOOL=ON ^
      -DARROW_HDFS:BOOL=ON ^
      -DARROW_MIMALLOC:BOOL=ON ^
      -DARROW_ORC:BOOL=OFF ^
      -DARROW_PARQUET:BOOL=ON ^
      -DARROW_PYTHON:BOOL=ON ^
      -DARROW_S3:BOOL=ON ^
      -DARROW_SIMD_LEVEL:STRING=NONE ^
      -DARROW_USE_GLOG:BOOL=ON ^
      -DARROW_WITH_BROTLI:BOOL=ON ^
      -DARROW_WITH_BZ2:BOOL=ON ^
      -DARROW_WITH_LZ4:BOOL=ON ^
      -DARROW_WITH_SNAPPY:BOOL=ON ^
      -DARROW_WITH_ZLIB:BOOL=ON ^
      -DARROW_WITH_ZSTD:BOOL=ON ^
      -DBUILD_SHARED_LIBS=ON ^
      -DCMAKE_BUILD_TYPE=release ^
      -DCMAKE_CXX_STANDARD=17 ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DCMAKE_UNITY_BUILD=ON ^
      -DBoost_NO_BOOST_CMAKE=ON ^
      -DLLVM_TOOLS_BINARY_DIR="%LIBRARY_BIN%" ^
      -DPython3_EXECUTABLE="%PYTHON%" ^
      %EXTRA_CMAKE_ARGS% ^
      ..
if errorlevel 1 exit 1

cmake --build . --target install --config Release
if errorlevel 1 exit 1

popd
