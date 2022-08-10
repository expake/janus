FROM fedora:36

RUN yum install -y libmicrohttpd-devel jansson-devel wget libtool unzip \
   openssl-devel libsrtp-devel sofia-sip-devel glib2-devel m4 automake \
   opus-devel libogg-devel libcurl-devel pkgconfig meson ninja-build \
   libconfig-devel gcc-c++ libtool meson cmake git doxygen graphviz

RUN cd ~ \
    # get libnice
    && git clone https://gitlab.freedesktop.org/libnice/libnice \ 
    && cd libnice \ 
    && meson --prefix=/usr build && ninja -C build && sudo ninja -C build install \
    # get libsrtp
    && cd ~ \
    && wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz \
    && tar xfv v2.2.0.tar.gz \
    && cd libsrtp-2.2.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library \
    && sudo make install \
    # get usrsctp
    && cd ~ \
    && git clone https://libwebsockets.org/repo/libwebsockets \
    && cd libwebsockets \
    && mkdir build \
    && cd build \
    && cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. \
    && make && sudo make install

ADD janus-gateway /root/janus-gateway

RUN cd /root/janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus --disable-rabbitmq --disable-mqtt --enable-docs \
    && make CFLAGS='-std=c99' \
    && make install \
    && make configs \
    && ln -s /opt/janus/bin/janus /bin/janus \
    && cd /root/ \
    && rm -rf libnice libwebsockets v2.2.0.tar.gz libsrtp-2.2.0
COPY conf/*.cfg /opt/janus/etc/janus/
EXPOSE 80 7088 8088 8188 8089
EXPOSE 10000-10200/udp
CMD /opt/janus/bin/janus --nat-1-1=${DOCKER_IP}