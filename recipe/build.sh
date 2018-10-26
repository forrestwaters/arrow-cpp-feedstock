#!/bin/bash

set -e
set -x

# Build dependencies
export ARROW_BUILD_TOOLCHAIN=$PREFIX

cd cpp
mkdir build-dir
cd build-dir

declare -a _CMAKE_EXTRA_CONFIG
if [[ ${HOST} =~ .*darwin.* ]]; then
    if [[ ${_XCODE_BUILD} == yes ]]; then
        _CMAKE_EXTRA_CONFIG+=(-G'Xcode')
        _CMAKE_EXTRA_CONFIG+=(-DCMAKE_OSX_ARCHITECTURES=x86_64)
        _CMAKE_EXTRA_CONFIG+=(-DCMAKE_OSX_SYSROOT=${CONDA_BUILD_SYSROOT})
        _VERBOSE=""
    fi
    unset MACOSX_DEPLOYMENT_TARGET
    export MACOSX_DEPLOYMENT_TARGET
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_AR=${AR})
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_RANLIB=${RANLIB})
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_LINKER=${LD})
fi

# CMake has a hard time coping with our hard-coding of c++ standard.  Arrow sets it in cmake (CMAKE_CXX_STANDARD)
if [[ ${target_platform} =~ .*linux.* ]]; then
    CXXFLAGS="${CXXFLAGS//-std=c++17/}"
    # I hate you so much CMake.
    LIBPTHREAD=$(find ${BUILD_PREFIX} -name "libpthread.so")
    _CMAKE_EXTRA_CONFIG+=("-DPTHREAD_LIBRARY=${LIBPTHREAD}")
else
    CXXFLAGS="${CXXFLAGS//-std=c++14/}"
fi

cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_UTILITIES=ON \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_JEMALLOC=ON \
    -DARROW_PLASMA=ON \
    -DARROW_PYTHON=ON \
    -DARROW_ORC=ON \
    -DARROW_PARQUET=ON \
    -DBROTLI_HOME=$PREFIX \
    -DFLATBUFFERS_HOME=$PREFIX \
    -DLZ4_HOME=$PREFIX \
    -DRAPIDJSON_HOME=$PREFIX \
    -DSNAPPY_HOME=$PREFIX \
    -DZLIB_HOME=$PREFIX \
    -DZSTD_HOME=$PREFIX \
    -DTHRIFT_HOME=$PREFIX \
    -DPROTOBUF_HOME=$PREFIX \
    -DCMAKE_C_COMPILER=$(type -p ${CC})     \
    -DCMAKE_CXX_COMPILER=$(type -p ${CXX})  \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
    -DARROW_CXXFLAGS="$CXXFLAGS" \
    "${_CMAKE_EXTRA_CONFIG[@]}" \
    ..

# make VERBOSE=1
make -j${CPU_COUNT} VERBOSE=1
make install
