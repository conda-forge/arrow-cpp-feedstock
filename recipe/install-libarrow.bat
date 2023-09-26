@echo on

:: Create temporary prefix to be able to install files more granularly
mkdir temp_prefix

cmake --install .\cpp\build --prefix=.\temp_prefix

dir %CD%
dir %CD%\temp_prefix
dir %CD%\temp_prefix\lib
dir %CD%\temp_prefix\share
dir %CD%\temp_prefix\include

if [%PKG_NAME%] == [libarrow] (
    move .\temp_prefix\lib\arrow.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\arrow.dll %LIBRARY_BIN%
    move .\temp_prefix\lib\parquet.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\parquet.dll %LIBRARY_BIN%
    move .\temp_prefix\lib\arrow_cuda.lib %LIBRARY_LIB% || true
    move .\temp_prefix\bin\arrow_cuda.dll %LIBRARY_BIN% || true
    move .\temp_prefix\lib\arrow.lib %LIBRARY_LIB%
    move .\temp_prefix\lib\pkgconfig\* %LIBRARY_LIB%\pkgconfig
    mkdir %LIBRARY_LIB%\cmake\Arrow
    move .\temp_prefix\lib\cmake\Arrow\* %LIBRARY_LIB%\cmake\Arrow
    mkdir %LIBRARY_LIB%\cmake\ArrowCUDA
    move .\temp_prefix\lib\cmake\ArrowCUDA\* %LIBRARY_LIB%\cmake\ArrowCUDA || true
    mkdir %LIBRARY_LIB%\cmake\Parquet
    move .\temp_prefix\lib\cmake\Parquet\* %LIBRARY_LIB%\cmake\Parquet
    mkdir %LIBRARY_PREFIX%\share\doc\arrow
    move .\temp_prefix\share\doc\arrow\* %LIBRARY_PREFIX%\share\doc\arrow
    mkdir %LIBRARY_PREFIX%\share\arrow
    xcopy /s /y .\temp_prefix\share\arrow %LIBRARY_PREFIX%\share\arrow
    mkdir %LIBRARY_PREFIX%\include\arrow
    xcopy /s /y .\temp_prefix\include\arrow %LIBRARY_PREFIX%\include\arrow
    mkdir %LIBRARY_PREFIX%\include\parquet
    xcopy /s /y .\temp_prefix\include\parquet %LIBRARY_PREFIX%\include\parquet
) else if [%PKG_NAME%] == [libarrow-acero] (
    move .\temp_prefix\lib\arrow_acero.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\arrow_acero.dll %LIBRARY_BIN%
    mkdir %LIBRARY_LIB%\cmake\ArrowAcero
    move .\temp_prefix\lib\cmake\ArrowAcero\* %LIBRARY_LIB%\cmake\ArrowAcero
) else if [%PKG_NAME%] == [libarrow-dataset] (
    move .\temp_prefix\lib\arrow_dataset.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\arrow_dataset.dll %LIBRARY_BIN%
    mkdir %LIBRARY_LIB%\cmake\ArrowDataset
    move .\temp_prefix\lib\cmake\ArrowDataset\* %LIBRARY_LIB%\cmake\ArrowDataset
) else if [%PKG_NAME%] == [libarrow-gandiva] (
    move .\temp_prefix\lib\gandiva.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\gandiva.dll %LIBRARY_BIN%
    mkdir %LIBRARY_LIB%\cmake\Gandiva
    move .\temp_prefix\lib\cmake\Gandiva\* %LIBRARY_LIB%\cmake\Gandiva
) else if [%PKG_NAME%] == [libarrow-substrait] (
    move .\temp_prefix\lib\arrow_substrait.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\arrow_substrait.dll %LIBRARY_BIN%
    mkdir %LIBRARY_LIB%\cmake\ArrowSubstrait
    move .\temp_prefix\lib\cmake\ArrowSubstrait\* %LIBRARY_LIB%\cmake\ArrowSubstrait
) else if [%PKG_NAME%] == [libarrow-flight] (
    move .\temp_prefix\lib\arrow_flight.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\arrow_flight.dll %LIBRARY_BIN%
    mkdir %LIBRARY_LIB%\cmake\ArrowFlight
    move .\temp_prefix\lib\cmake\ArrowFlight\* %LIBRARY_LIB%\cmake\ArrowFlight
) else if [%PKG_NAME%] == [libarrow-flight-sql] (
    move .\temp_prefix\lib\arrow_flight_sql.lib %LIBRARY_LIB%
    move .\temp_prefix\bin\arrow_flight_sql.dll %LIBRARY_BIN%
    mkdir %LIBRARY_LIB%\cmake\ArrowFlightSql
    move .\temp_prefix\lib\cmake\ArrowFlightSql\* %LIBRARY_LIB%\cmake\ArrowFlightSql
)

dir %LIBRARY_LIB%
dir %LIBRARY_BIN%

:: clean up temp_prefix between builds
rmdir /s /q temp_prefix
