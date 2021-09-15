FROM ubuntu:20.04 as build
ARG GHC_VER=8.10.4
ARG CABAL_VER=3.4.0.0
ENV DEBIAN_FRONTEND=noninteractive
# Install dependencies 
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y curl wget git perl python3 ghc \
    && apt-get install -y make automake autoconf llvm-9 build-essential binutils-gold \
    && apt-get install -y pkg-config libffi-dev libgmp-dev \
    && apt-get install -y libssl-dev libtinfo-dev libsystemd-dev \
    && apt-get install -y zlib1g-dev g++ libncursesw5 libtool libnuma-dev \
    && apt-get clean

WORKDIR /src
    # Build GHC from source 
RUN curl -sSLO https://downloads.haskell.org/~ghc/${GHC_VER}/ghc-${GHC_VER}-src.tar.xz \
    && tar xf ghc-${GHC_VER}-src.tar.xz && rm -f ghc-${GHC_VER}-src.tar.xz \
    && cd ghc-${GHC_VER} \
    && if [ $(uname -m) = "aarch64" ]; then \
    # Disable OFD locking on aarch64
    # https://gitlab.haskell.org/ghc/ghc/-/issues/17918
    sed -i -e 's/HAVE_OFD_LOCKING], \[1]/HAVE_OFD_LOCKING], \[0]/g' libraries/base/configure.ac; fi \
    && cp mk/build.mk.sample mk/build.mk \
    && echo 'BuildFlavour=quick-no_profiled_libs' >> mk/build.mk \
    && echo 'BeConservative=YES' >> mk/build.mk \
    && autoreconf \
    && ./configure --disable-ld-override LD=ld.gold \
    # See https://unix.stackexchange.com/questions/519092/what-is-the-logic-of-using-nproc-1-in-make-command
    && make -j$((`nproc`+1)) \
    # Produce a binary distribution
    && make binary-dist 
