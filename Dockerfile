FROM alpine:3.19.1

RUN apk --no-cache add \
    gcc \
    make \
    libc-dev \
    openssl-dev \
    && wget https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz \
    && tar -xzvf 0.9.3.tar.gz \
    && cd 3proxy-0.9.3 \
    && make -f Makefile.Linux \
    && mv bin/3proxy /usr/local/bin/3proxy \
    && rm -rf /3proxy-0.9.3 \
    && apk del \
    gcc \
    make \
    libc-dev \
    openssl-dev

EXPOSE $PORT

CMD ["3proxy", "/etc/3proxy/3proxy.cfg"]
