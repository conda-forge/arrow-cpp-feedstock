#!/bin/sh

set -e
set -x

# Build dependencies
export ARROW_HOME=$PREFIX
export PARQUET_HOME=$PREFIX
export SETUPTOOLS_SCM_PRETEND_VERSION=$PKG_VERSION
export PYARROW_BUILD_TYPE=release
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
if [[ "$(uname -m)" = "ppc64le" || "$(uname -m)" = "aarch64" ]]
then
  export PYARROW_WITH_GANDIVA=0
else
  export PYARROW_WITH_GANDIVA=1
fi
export PYARROW_WITH_HDFS=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PLASMA=1
export PYARROW_WITH_S3=1
BUILD_EXT_FLAGS=""

# Enable CUDA support
if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" != "None" ]]
then
    export PYARROW_WITH_CUDA=1
    BUILD_EXT_FLAGS="${BUILD_EXT_FLAGS} --with-cuda"
else
    export PYARROW_WITH_CUDA=0
fi

cd python

$PYTHON setup.py \
        build_ext $BUILD_EXT_FLAGS \
        install --single-version-externally-managed \
                --record=record.txt
