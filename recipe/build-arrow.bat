@echo on

mkdir cpp\build
pushd cpp\build

:: Enable CUDA support
if "%cuda_compiler_version%"=="None" (
    set "EXTRA_CMAKE_ARGS=-DARROW_CUDA=OFF"
) else (
    set "EXTRA_CMAKE_ARGS=-DARROW_CUDA=ON"
)

set "ARROW_ACERO=OFF"
set "ARROW_DATASET=OFF"
set "ARROW_FLIGHT=OFF"
set "ARROW_FLIGHT_TLS=OFF"
set "ARROW_FLIGHT_SQL=OFF"
set "ARROW_GANDIVAT=OFF"
set "ARROW_SUBSTRAIT=OFF"
:: Set CMAKE components based on package
if [%PKG_NAME%] == [libarrow-acero] (
    set "ARROW_ACERO=ON"
) else if [%PKG_NAME%] == [libarrow-dataset] (
    set "ARROW_ACERO=ON"
    set "ARROW_DATASET=ON"
) else if [%PKG_NAME%] == [libarrow-gandiva] (
    set "ARROW_GANDIVA=ON"
) else if [%PKG_NAME%] == [libarrow-substrait] (
    set "ARROW_SUBSTRAIT=ON"
) else if [%PKG_NAME%] == [libarrow-flight] (
    set "ARROW_FLIGHT=ON"
    set "ARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS=ON"
) else if [%PKG_NAME%] == [libarrow-flight-sql] (
    set "ARROW_FLIGHT=ON"
    set "ARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS=ON"
    set "ARROW_FLIGHT_SQL=ON"
)

:: # reusable variable for dependencies we cannot yet unvendor
set "READ_RECIPE_META_YAML_WHY_NOT=OFF"

:: for available switches see
:: https://github.com/apache/arrow/blame/apache-arrow-12.0.0/cpp/cmake_modules/DefineOptions.cmake
cmake -G "Ninja" ^
      -DARROW_ACERO=!ARROW_ACERO! ^
      -DARROW_BOOST_USE_SHARED:BOOL=ON ^
      -DARROW_BUILD_STATIC:BOOL=OFF ^
      -DARROW_BUILD_TESTS:BOOL=OFF ^
      -DARROW_BUILD_UTILITIES:BOOL=OFF ^
      -DARROW_COMPUTE:BOOL=ON ^
      -DARROW_CSV:BOOL=ON ^
      -DARROW_DATASET:BOOL=!ARROW_DATASET! ^
      -DARROW_DEPENDENCY_SOURCE=SYSTEM ^
      -DARROW_FILESYSTEM:BOOL=ON ^
      -DARROW_FLIGHT:BOOL=!ARROW_FLIGHT! ^
      -DARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS:BOOL=!ARROW_FLIGHT_REQUIRE_TLSCREDENTIALSOPTIONS! ^
      -DARROW_FLIGHT_SQL:BOOL=!ARROW_FLIGHT_SQL! ^
      -DARROW_GANDIVA:BOOL=!ARROW_GANDIVA! ^
      -DARROW_GCS:BOOL=ON ^
      -DARROW_HDFS:BOOL=ON ^
      -DARROW_JSON:BOOL=ON ^
      -DARROW_MIMALLOC:BOOL=ON ^
      -DARROW_ORC:BOOL=ON ^
      -DARROW_PACKAGE_PREFIX="%LIBRARY_PREFIX%" ^
      -DARROW_PARQUET:BOOL=ON ^
      -DARROW_S3:BOOL=ON ^
      -DARROW_SIMD_LEVEL:STRING=NONE ^
      -DARROW_SUBSTRAIT:BOOL=!ARROW_SUBSTRAIT! ^
      -DARROW_USE_GLOG:BOOL=ON ^
      -DARROW_WITH_BROTLI:BOOL=ON ^
      -DARROW_WITH_BZ2:BOOL=ON ^
      -DARROW_WITH_LZ4:BOOL=ON ^
      -DARROW_WITH_NLOHMANN_JSON:BOOL=ON ^
      -DARROW_WITH_OPENTELEMETRY:BOOL=%READ_RECIPE_META_YAML_WHY_NOT% ^
      -DARROW_WITH_SNAPPY:BOOL=ON ^
      -DARROW_WITH_ZLIB:BOOL=ON ^
      -DARROW_WITH_ZSTD:BOOL=ON ^
      -DBUILD_SHARED_LIBS=ON ^
      -DBoost_NO_BOOST_CMAKE=ON ^
      -DCMAKE_BUILD_TYPE=release ^
      -DCMAKE_CXX_STANDARD=17 ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DCMAKE_UNITY_BUILD=ON ^
      -DLLVM_TOOLS_BINARY_DIR="%LIBRARY_BIN%" ^
      -DPARQUET_REQUIRE_ENCRYPTION:BOOL=ON ^
      -DPython3_EXECUTABLE="%PYTHON%" ^
      %EXTRA_CMAKE_ARGS% ^
      ..
if %ERRORLEVEL% neq 0 exit 1

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 exit 1

popd

:: clean up between builds (and to save space)
rmdir /s /q cpp\build
