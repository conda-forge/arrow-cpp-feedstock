#!/bin/bash
set -ex

# temporary prefix to be able to install files more granularly
mkdir temp_prefix

cmake --install ./cpp/build --prefix=./temp_prefix

if [[ "${PKG_NAME}" == libarrow ]]; then
    # only libarrow
    mv ./temp_prefix/lib/libarrow.* $PREFIX/lib
    mv ./temp_prefix/lib/libparquet.* $PREFIX/lib
    mv ./temp_prefix/lib/libarrow_cuda.* $PREFIX/lib || true
    mv ./temp_prefix/lib/cmake/* $PREFIX/lib/cmake
    mv ./temp_prefix/share/arrow/* $PREFIX/share/arrow
    mv ./temp_prefix/share/gdb/* $PREFIX/share/gdb
    mv ./temp_prefix/share/doc/* $PREFIX/share/doc
    mv ./temp_prefix/include/* $PREFIX/include
elif [[ "${PKG_NAME}" == libarrow-acero ]]; then
    # only libarrow-acero
    mv ./temp_prefix/lib/libarrow_acero.* $PREFIX/lib
elif [[ "${PKG_NAME}" == libarrow-dataset ]]; then
    # only libarrow-dataset
    mv ./temp_prefix/lib/libarrow_dataset.* $PREFIX/lib
elif [[ "${PKG_NAME}" == libarrow-gandiva ]]; then
    # only libarrow-gandiva
    mv ./temp_prefix/lib/libgandiva.* $PREFIX/lib
elif [[ "${PKG_NAME}" == libarrow-substrait ]]; then
    # only libarrow-substrait
    mv ./temp_prefix/lib/libarrow_substrait.* $PREFIX/lib
elif [[ "${PKG_NAME}" == libarrow-flight ]]; then
    # only libarrow-flight
    mv ./temp_prefix/lib/libarrow_flight.* $PREFIX/lib
    mv ./temp_prefix/lib/libarrow_flight_transport_ucx.* $PREFIX/lib || true
elif [[ "${PKG_NAME}" == libarrow-flight-sql ]]; then
    # only libarrow-flight-sql
    mv ./temp_prefix/lib/libarrow_flight_sql.* $PREFIX/lib
else
    # libarrow-all: install everything
    cmake --install ./cpp/build --prefix=$PREFIX
fi

# Clean up temp_prefix
rm -rf temp_prefix
