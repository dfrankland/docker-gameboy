FROM buildpack-deps:stretch

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
    ninja-build; \
  cd /; \
  curl -L https://api.github.com/repos/$LLVMZ80_GITHUB_USER_NAME/$LLVMZ80_GITHUB_REPO_NAME/tarball/$LLVMZ80_GITHUB_REPO_COMMIT | tar -xvzf -; \
  curl -L https://api.github.com/repos/$CLANG_GITHUB_USER_NAME/$CLANG_GITHUB_REPO_NAME/tarball/$CLANG_GITHUB_REPO_COMMIT | tar -xvzf -; \
  \
  mkdir -p /llvm/tools/clang; \
  mkdir -p /llvm/build/Debug; \
  \
  rsync -a /$LLVMZ80_GITHUB_USER_NAME-$LLVMZ80_GITHUB_REPO_NAME-$LLVMZ80_GITHUB_REPO_COMMIT/ /llvm; \
  rsync -a /$CLANG_GITHUB_USER_NAME-$CLANG_GITHUB_REPO_NAME-$CLANG_GITHUB_REPO_COMMIT/ /llvm/tools/clang; \
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

CMD ["/bin/bash", "-c", "/llvm/build/Debug/bin/clang -target gbz80 -xc - -S -o- <<<'void test(void){}'"]
