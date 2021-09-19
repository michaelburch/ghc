WORKDIR /src
    # Build GHC from source 
RUN apt install -y ghc \
    && curl -sSLO https://downloads.haskell.org/~ghc/${GHC_VER}/ghc-${GHC_VER}-src.tar.xz \
    && tar xf ghc-${GHC_VER}-src.tar.xz && rm -f ghc-${GHC_VER}-src.tar.xz \
    && cd ghc-${GHC_VER} \
    && if [ $(uname -m) = "aarch64" ]; then \
    # Disable OFD locking on aarch64
    # https://gitlab.haskell.org/ghc/ghc/-/issues/17918
    cd libraries/base; \
    sed -i -e 's/HAVE_OFD_LOCKING], \[1]/HAVE_OFD_LOCKING], \[0]/g' configure.ac; \
    autoreconf; cd ../../; fi \
    && cp mk/build.mk.sample mk/build.mk \
    && echo 'BuildFlavour=${GHC_FLAVOR}' >> mk/build.mk \
    && echo 'BeConservative=YES' >> mk/build.mk \
    && autoreconf \
    && ./configure --prefix /usr/local --disable-ld-override LD=ld.gold \
    # See https://unix.stackexchange.com/questions/519092/what-is-the-logic-of-using-nproc-1-in-make-command
    && make -j$((`nproc`+1)) \
    # Produce a binary distribution
    && make install \
    # Cleanup
    && cd /src && rm -rf /src/* \
    && apt remove -y ghc && apt autoremove -y && apt clean \
    && ghc --version

RUN if [ $(uname -m) = "aarch64" ]; then \
      wget -q https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VER}/cabal-install-${CABAL_VER}-aarch64-ubuntu-18.04.tar.xz \
    && tar -xf cabal-install-${CABAL_VER}-aarch64-ubuntu-18.04.tar.xz; \
    elif [ $(uname -m) = "x86_64" ]; then \
      wget -q https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VER}/cabal-install-${CABAL_VER}-x86_64-ubuntu-16.04.tar.xz \
    && tar -xf cabal-install-${CABAL_VER}-x86_64-ubuntu-16.04.tar.xz; \
    fi \
    && mv cabal /usr/local/bin/ && rm *.xz \
    && cabal --version

WORKDIR /

