@echo on
setlocal EnableDelayedExpansion

:: Create temporary prefix to be able to install files more granularly
mkdir temp_prefix

cmake --install .\cpp\build --prefix=.\temp_prefix

if [%PKG_NAME%] == [libarrow] (
    mv .\temp_prefix\Library\lib\libarrow.* $PREFIX\Library\lib
    mv .\temp_prefix\Library\lib\libparquet.* $PREFIX\Library\lib
    mv .\temp_prefix\Library\lib\libarrow_cuda.* $PREFIX\Library\lib || true
    mv .\temp_prefix\Library\lib\libarrow.* $PREFIX\Library\lib
    mv .\temp_prefix\Library\lib\cmake\* $PREFIX\Library\lib\cmake
    mv .\temp_prefix\Library\lib\share\arrow\* $PREFIX\Library\share\arrow
    mv .\temp_prefix\Library\lib\share\gdb\* $PREFIX\Library\share\gdb
    mv .\temp_prefix\Library\lib\share\doc\* $PREFIX\Library\share\doc
    mv .\temp_prefix\Library\lib\include\* $PREFIX\Library\include
) else if [%PKG_NAME%] == [libarrow-acero] (
    mv .\temp_prefix\Library\lib\libarrow_acero.* $PREFIX\Library\lib
) else if [%PKG_NAME%] == [libarrow-dataset] (
    mv .\temp_prefix\Library\lib\libarrow_dataset.* $PREFIX\Library\lib
) else if [%PKG_NAME%] == [libarrow-gandiva] (
    mv .\temp_prefix\Library\lib\libgandiva.* $PREFIX\Library\lib
) else if [%PKG_NAME%] == [libarrow-substrait] (
    mv .\temp_prefix\Library\lib\libarrow_substrait.* $PREFIX\Library\lib
) else if [%PKG_NAME%] == [libarrow-flight] (
    mv .\temp_prefix\Library\lib\libarrow_flight.* $PREFIX\Library\lib
) else if [%PKG_NAME%] == [libarrow-flight-sql] (
    mv .\temp_prefix\Library\lib\libarrow_flight_sql.* $PREFIX\Library\lib
)

:: clean up temp_prefix between builds
rmdir /s /q temp_prefix
