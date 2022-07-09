#! /usr/bin/env bash

set -ex

# Create deps folder.
cd /src
mkdir -p deps
cd deps

# Download and build GMP.
wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz
tar xvf gmp-6.2.1.tar.xz
cd gmp-6.2.1/
./configure --with-pic --enable-cxx
make
make check
sudo make install
cd ..

# Download and build Bitwuzla.
git clone https://github.com/bitwuzla/bitwuzla.git
cd bitwuzla
./contrib/setup-cadical.sh
./contrib/setup-btor2tools.sh
./contrib/setup-symfpu.sh
CMAKE_OPTS="-DCMAKE_POSITION_INDEPENDENT_CODE=ON" ./configure.sh --prefix $(pwd)/install
cd build
make
cd lib
ar cqT libbitwuzlam.a libbitwuzla.a ../../deps/install/lib/libbtor2parser.a ../../deps/cadical/build/libcadical.a ../../../gmp-6.2.1/.libs/libgmp.a && echo -e "create libbitwuzlam.a\naddlib libbitwuzlam.a\nsave\nend" | ar -M
mv libbitwuzlam.a libbitwuzla.a
cd ..
make install
cd ../..

# Download Z3.
wget https://github.com/Z3Prover/z3/releases/download/z3-4.8.17/z3-4.8.17-x64-glibc-2.31.zip
unzip z3-4.8.17-x64-glibc-2.31.zip

# Install Capstone.
wget https://github.com/aquynh/capstone/archive/4.0.2.tar.gz
tar -xf ./4.0.2.tar.gz
cd ./capstone-4.0.2
bash ./make.sh
sudo make install
cd ..

# Download LLVM.
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
tar -xf clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz

# Set environment variables for building Triton.
export Z3_INCLUDE_DIRS=$(pwd)/z3-4.8.17-x64-glibc-2.31/include
export Z3_LIBRARIES=$(pwd)/z3-4.8.17-x64-glibc-2.31/bin/libz3.a
export CAPSTONE_INCLUDE_DIRS=/usr/include
export CAPSTONE_LIBRARIES=/usr/lib/libcapstone.a
export BITWUZLA_INTERFACE=On
export BITWUZLA_INCLUDE_DIRS=$(pwd)/bitwuzla/install/include
export BITWUZLA_LIBRARIES=$(pwd)/bitwuzla/install/lib/libbitwuzla.a
export LLVM_INTERFACE=ON
export CMAKE_PREFIX_PATH=$($(pwd)/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-/bin/llvm-config --prefix)

cd ..

# Build Triton Python wheel package for Python 3.8.
export PYTHON_BINARY=/opt/python/cp38-cp38/bin/python
export PYTHON_INCLUDE_DIRS=$($PYTHON_BINARY -c "from sysconfig import get_paths; print(get_paths()['include'])")
export PYTHON_LIBRARY=$($PYTHON_BINARY -c "from sysconfig import get_paths; print(get_paths()['include'])")

$PYTHON_BINARY setup.py bdist_wheel --dist-dir wheel-temp

# Build Triton Python wheel package for Python 3.9.
export PYTHON_BINARY=/opt/python/cp39-cp39/bin/python
export PYTHON_INCLUDE_DIRS=$($PYTHON_BINARY -c "from sysconfig import get_paths; print(get_paths()['include'])")
export PYTHON_LIBRARY=$($PYTHON_BINARY -c "from sysconfig import get_paths; print(get_paths()['include'])")

$PYTHON_BINARY setup.py bdist_wheel --dist-dir wheel-temp

# Build Triton Python wheel package for Python 3.10.
export PYTHON_BINARY=/opt/python/cp310-cp310/bin/python
export PYTHON_INCLUDE_DIRS=$($PYTHON_BINARY -c "from sysconfig import get_paths; print(get_paths()['include'])")
export PYTHON_LIBRARY=$($PYTHON_BINARY -c "from sysconfig import get_paths; print(get_paths()['include'])")

$PYTHON_BINARY setup.py bdist_wheel --dist-dir wheel-temp

# Repair wheels.
for whl in wheel-temp/*.whl; do
    auditwheel repair "$whl" -w wheel-final
done

chown -R 1000:1000 wheel-final
