mkdir "%SRC_DIR%"\cpp\build
pushd "%SRC_DIR%"\cpp\build

cmake -G "%CMAKE_GENERATOR%" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DARROW_DEPENDENCY_SOURCE=SYSTEM ^
      -DARROW_PACKAGE_PREFIX="%LIBRARY_PREFIX%" ^
      -DPYTHON_EXECUTABLE="%LIBRARY_PREFIX%\bin\python.exe" ^
      -DARROW_BOOST_USE_SHARED:BOOL=ON ^
      -DARROW_BUILD_TESTS:BOOL=OFF ^
      -DARROW_BUILD_UTILITIES:BOOL=OFF ^
      -DARROW_BUILD_STATIC:BOOL=OFF ^
      -DCMAKE_BUILD_TYPE=release ^
      -DARROW_PYTHON:BOOL=ON ^
      -DARROW_PARQUET:BOOL=ON ^
      -DARROW_GANDIVA:BOOL=OFF ^
      -DARROW_ORC:BOOL=ON ^
      ..

cmake --build . --target INSTALL --config Release

popd
