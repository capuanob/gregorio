# Build Stage
FROM fuzzers/aflplusplus:3.12c as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git texlive-full build-essential autoconf libltdl7-dev flex bison fontforge python-pygments

## Add source code to the build stage.
WORKDIR /
RUN git clone https://github.com/capuanob/gregorio.git
WORKDIR /gregorio
RUN git checkout mayhem

## Build
RUN mkdir -p build
RUN ./build.sh --prefix=/gregorio/build --jobs=8 || true

## Prepare all library dependencies for copy
RUN mkdir /deps
RUN cp `ldd ./src/gregorio-* | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :
RUN cp `ldd /usr/local/bin/afl-fuzz | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :
RUN ln -s `which unzip` /unzip

## Package Stage

#FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /usr/local/bin/afl-fuzz /afl-fuzz
COPY --from=builder /gregorio/src/gregorio-* /gregorio
COPY --from=builder /deps /usr/lib
COPY --from=builder /gregorio/corpus /tests

env AFL_SKIP_CPUFREQ=1

ENTRYPOINT ["/afl-fuzz", "-i", "/tests", "-o", "/out"]
CMD ["/gregorio", "-s", "-S"]
