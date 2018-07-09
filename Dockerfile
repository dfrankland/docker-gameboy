FROM buildpack-deps:stretch

ARG RGBDS_GITHUB_USER_NAME=rednex
ARG RGBDS_GITHUB_REPO_NAME=rgbds
ARG RGBDS_GITHUB_REPO_COMMIT=e2de106

ARG GBDK_GITHUB_USER_NAME=hschmitt
ARG GBDK_GITHUB_REPO_NAME=gbdk
ARG GBDK_GITHUB_REPO_COMMIT=d7707bf

ENV GBDK_INCLUDE /$GBDK_GITHUB_USER_NAME-$GBDK_GITHUB_REPO_NAME-$GBDK_GITHUB_REPO_COMMIT/include

ARG LLVMZ80_GITHUB_USER_NAME=Bevinsky
ARG LLVMZ80_GITHUB_REPO_NAME=llvm-gbz80
ARG LLVMZ80_GITHUB_REPO_COMMIT=eae7104

ARG CLANG_GITHUB_USER_NAME=Bevinsky
ARG CLANG_GITHUB_REPO_NAME=clang-gbz80
ARG CLANG_GITHUB_REPO_COMMIT=20594c8

RUN set -eux; \
  \
  apt-get update; \
  apt-get install -y \
    git \
    curl \
    rsync \
    cmake \
    ninja-build \
    byacc \
    flex \
    pkg-config \
    libpng-dev; \
  \
  cd /; \
  curl -L https://api.github.com/repos/$RGBDS_GITHUB_USER_NAME/$RGBDS_GITHUB_REPO_NAME/tarball/$RGBDS_GITHUB_REPO_COMMIT | tar -xvzf -; \
  curl -L https://api.github.com/repos/$GBDK_GITHUB_USER_NAME/$GBDK_GITHUB_REPO_NAME/tarball/$GBDK_GITHUB_REPO_COMMIT | tar -xvzf -; \
  curl -L https://api.github.com/repos/$LLVMZ80_GITHUB_USER_NAME/$LLVMZ80_GITHUB_REPO_NAME/tarball/$LLVMZ80_GITHUB_REPO_COMMIT | tar -xvzf -; \
  curl -L https://api.github.com/repos/$CLANG_GITHUB_USER_NAME/$CLANG_GITHUB_REPO_NAME/tarball/$CLANG_GITHUB_REPO_COMMIT | tar -xvzf -; \
  \
  cd /$RGBDS_GITHUB_USER_NAME-$RGBDS_GITHUB_REPO_NAME-$RGBDS_GITHUB_REPO_COMMIT; \
  make; \
  make install; \
  \
  mkdir -p /llvm/tools/clang; \
  mkdir -p /llvm/build/Debug; \
  \
  rsync -a /$LLVMZ80_GITHUB_USER_NAME-$LLVMZ80_GITHUB_REPO_NAME-$LLVMZ80_GITHUB_REPO_COMMIT/ /llvm; \
  rsync -a /$CLANG_GITHUB_USER_NAME-$CLANG_GITHUB_REPO_NAME-$CLANG_GITHUB_REPO_COMMIT/ /llvm/tools/clang; \
  \
  rm -rf \
    /$LLVMZ80_GITHUB_USER_NAME-$LLVMZ80_GITHUB_REPO_NAME-$LLVMZ80_GITHUB_REPO_COMMIT \
    /$CLANG_GITHUB_USER_NAME-$CLANG_GITHUB_REPO_NAME-$CLANG_GITHUB_REPO_COMMIT; \
  \
  cd /llvm/build/Debug; \
  cmake ../.. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DLLVM_ENABLE_ASSERTIONS=On \
    -DLLVM_ENABLE_PEDANTIC=Off \
    -DLLVM_ENABLE_WARNINGS=Off \
    -DLLVM_TARGETS_TO_BUILD= \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=GBZ80 \
    -DLLVM_PARALLEL_COMPILE_JOBS=4 \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DBUILD_SHARED_LIBS=ON; \
  cmake --build .;

ENV PATH /llvm/build/Debug/bin:$PATH

CMD ["/bin/bash", "-c", "clang -target gbz80 -xc - -S -o- <<<'void test(void){}'"]
