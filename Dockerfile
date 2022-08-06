# Build Stage
FROM fuzzers/aflplusplus:3.12c as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y texlive-full build-essential autoconf libltdl7-dev flex bison fontforge python-pygments

ADD . /gregorio
WORKDIR /gregorio

## Build
RUN mkdir -p build
env CC="afl-clang-fast"

RUN ./build.sh --prefix=/gregorio/build --jobs=$(nproc) || true


## Package Stage
FROM fuzzers/aflplusplus:3.12c
COPY --from=builder /gregorio/src/gregorio-6* /gregorio
COPY --from=builder /gregorio/corpus /tests

ENTRYPOINT ["afl-fuzz", "-i", "/tests", "-o", "/out"]
CMD ["/gregorio", "--stdin", "--stdout"]
