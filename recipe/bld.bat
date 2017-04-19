mkdir "%SRC_DIR%"\cpp\build
pushd "%SRC_DIR%"\cpp\build

cmake -G "Visual Studio 14 2015 Win64" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DARROW_BOOST_USE_SHARED:BOOL=ON ^
      -DARROW_BUILD_TESTS:BOOL=OFF ^
      -DARROW_BUILD_UTILITIES:BOOL=OFF ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DARROW_CXXFLAGS="/WX" ^
      -DARROW_PYTHON=on ^
      ..

cmake --build . --target INSTALL --config Release

popd
