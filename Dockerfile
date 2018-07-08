FROM buildpack-deps:stretch

# Same commit as the SVN repo:
# http://llvm.org/svn/llvm-project/llvm/trunk@316129
ARG LLVM_GITHUB_USER_NAME=llvm-mirror
ARG LLVM_GITHUB_REPO_NAME=llvm
ARG LLVM_GITHUB_REPO_COMMIT=b5cb868

# Same commit as the SVN repo:
# http://llvm.org/svn/llvm-project/cfe/trunk@316130
ARG CLANG_GITHUB_USER_NAME=llvm-mirror
ARG CLANG_GITHUB_REPO_NAME=clang
ARG CLANG_GITHUB_REPO_COMMIT=ac9a20e

ARG LLVMZ80_GITHUB_USER_NAME=jacobly0
ARG LLVMZ80_GITHUB_REPO_NAME=llvm-z80
ARG LLVMZ80_GITHUB_REPO_COMMIT=71ec7b8

RUN set -eux; \
  \
  apt-get update; \
  apt-get install -y \
    git \
    curl \
    rsync \
    cmake \
    ninja-build; \
  \
  cd /; \
  curl -L https://api.github.com/repos/$LLVM_GITHUB_USER_NAME/$LLVM_GITHUB_REPO_NAME/tarball/$LLVM_GITHUB_REPO_COMMIT | tar -xvzf -; \
  curl -L https://api.github.com/repos/$CLANG_GITHUB_USER_NAME/$CLANG_GITHUB_REPO_NAME/tarball/$CLANG_GITHUB_REPO_COMMIT | tar -xvzf -; \
  curl -L https://api.github.com/repos/$LLVMZ80_GITHUB_USER_NAME/$LLVMZ80_GITHUB_REPO_NAME/tarball/$LLVMZ80_GITHUB_REPO_COMMIT | tar -xvzf -; \
  \
  mkdir -p /llvm/tools/clang; \
  mkdir -p /llvm/build/Debug; \
  \
  rsync -a /$LLVM_GITHUB_USER_NAME-$LLVM_GITHUB_REPO_NAME-$LLVM_GITHUB_REPO_COMMIT/ /llvm; \
  rsync -a /$CLANG_GITHUB_USER_NAME-$CLANG_GITHUB_REPO_NAME-$CLANG_GITHUB_REPO_COMMIT/ /llvm/tools/clang; \
  rsync -a /$LLVMZ80_GITHUB_USER_NAME-$LLVMZ80_GITHUB_REPO_NAME-$LLVMZ80_GITHUB_REPO_COMMIT/ /llvm; \
  \
  rm -rf \
    /$LLVM_GITHUB_USER_NAME-$LLVM_GITHUB_REPO_NAME-$LLVM_GITHUB_REPO_COMMIT \
    /$CLANG_GITHUB_USER_NAME-$CLANG_GITHUB_REPO_NAME-$CLANG_GITHUB_REPO_COMMIT \
    /$LLVMZ80_GITHUB_USER_NAME-$LLVMZ80_GITHUB_REPO_NAME-$LLVMZ80_GITHUB_REPO_COMMIT; \
  \
  cd /llvm/build/Debug; \
  cmake ../.. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DLLVM_ENABLE_ASSERTIONS=On \
    -DLLVM_ENABLE_PEDANTIC=Off \
    -DLLVM_ENABLE_WARNINGS=Off \
    -DLLVM_TARGETS_TO_BUILD= \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Z80 \
    -DLLVM_PARALLEL_COMPILE_JOBS=4 \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DBUILD_SHARED_LIBS=ON; \
  cmake --build .;

ENV PATH /llvm/build/Debug/bin:$PATH

CMD ["/bin/bash", "-c", "clang -target gbz80 -xc - -S -o- <<<'void test(void){}'"]
