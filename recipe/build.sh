#!/bin/bash

set -e
set -x
# pulled from https://github.com/AnacondaRecipes/libnetcdf-feedstock/blob/master/recipe/build.sh
declare -a CMAKE_PLATFORM_FLAGS
if [[ ${HOST} =~ .*darwin.* ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
  export LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,-dead_strip_dylibs//g")
else
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")
fi

if [ "$(uname)" = "Linux" ] ; then
  export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
fi

mkdir cpp/build
pushd cpp/build

cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_PACKAGE_PREFIX=$PREFIX \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_JEMALLOC=ON \
    -DARROW_PLASMA=ON \
    -DARROW_PYTHON=ON \
    -DARROW_PARQUET=ON \
    -DARROW_GANDIVA=OFF \
    -DARROW_ORC=ON \
    -DORC_HOME=$PREFIX \
    -DCMAKE_AR=${AR} \
    -DCMAKE_RANLIB=${RANLIB} \
    -DPYTHON_EXECUTABLE="${PYTHON}" \
    -DBoost_NO_BOOST_CMAKE=ON \
    -GNinja \
    ${CMAKE_PLATFORM_FLAGS[@]} \
    ..

ninja install

popd
