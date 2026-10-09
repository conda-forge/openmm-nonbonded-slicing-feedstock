#!/bin/bash

set -euxo pipefail

rm -rf build || true

# conda-build exports the openmm variant, which avoids importing openmm (impossible when cross-compiling)
OPENMM_VERSION=${openmm:-$(python -c 'import openmm; print(openmm.__version__)')}

CMAKE_FLAGS="-DOPENMM_DIR=${PREFIX} -DOPENMM_VERSION=${OPENMM_VERSION}"
CMAKE_FLAGS+=" -DVKFFT_INCLUDE_DIR=${SRC_DIR}/vkfft/vkFFT"
if [[ "$target_platform" == osx* ]]; then
    CMAKE_FLAGS+=" -DCMAKE_OSX_SYSROOT=${CONDA_BUILD_SYSROOT}"
    CMAKE_FLAGS+=" -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}"
fi

# Build in subdirectory and install.
mkdir -p build
cd build
cmake ${CMAKE_ARGS} ${CMAKE_FLAGS} ${SRC_DIR}
make -j$CPU_COUNT install
make -j$CPU_COUNT PythonInstall

# Include test executables too
mkdir -p ${PREFIX}/share/${PKG_NAME}/tests
if [[ "$target_platform" == osx* ]]; then
    find . -name 'Test*' -perm +0111 -type f -exec cp {} ${PREFIX}/share/${PKG_NAME}/tests/ \;
else
    find . -name 'Test*' -executable -type f -exec cp {} ${PREFIX}/share/${PKG_NAME}/tests/ \;
fi
