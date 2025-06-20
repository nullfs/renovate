FROM ubuntu:25.04

RUN apt update && apt install -y pkgconf curl rsync autoconf file make zip gcc g++ libasound2-dev libjpeg-dev \
                                 libgif-dev libpng-dev liblcms2-dev libcups2-dev libfontconfig-dev libx11-dev \
                                 libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev zsh

SHELL ["/bin/zsh", "-c"]

ARG JDK_VERSION
ARG JDK_UPDATES
ARG JDK_RELEASE

RUN --mount=type=tmpfs,target=/tmp --mount=type=bind,target=/mnt <<-EOF
    if [ "$(findmnt -o FSTYPE -n /tmp)" != tmpfs ]; then
        echo 'The /tmp mount point was not set up correctly.' 2>&1
        exit 1
    else
        cd /tmp
    fi

    PATH="$PWD/images/jdk/bin:$PWD/java/bin:$PATH"

    curl -L $JDK_RELEASE -o >(tar -xzf - --xform 's/[^\/]*/java/') \
         -L $JDK_UPDATES -o >(tar -xzf - --xform 's/[^\/]*/jdk/') \
         --parallel --retry 5 --connect-timeout 10

    bash jdk/configure --with-jvm-features=link-time-opt \
        --with-libjpeg=system --with-giflib=system --with-libpng=system --with-lcms=system --with-zlib=system \
        --with-extra-cflags="-O3 -march=znver3 -ftree-vectorize -floop-nest-optimize -fipa-pta" \
        --with-extra-cxxflags="-O3 -march=znver3 -ftree-vectorize -floop-nest-optimize -fipa-pta" \
        --with-native-debug-symbols=none \
        --with-source-date=2025-01-01 \
        --with-version-string=${JDK_VERSION:4} \
        --disable-absolute-paths-in-output \
        --enable-headless-only \
        --enable-linktime-gc && make images || exit 1

    jlink --add-modules $(tr '\n' , < /mnt/module.conf) \
          --strip-debug \
          --generate-cds-archive \
          --no-header-files \
          --no-man-pages \
          --output /opt/java
EOF

RUN <<-EOF
    if id 200; then
        echo 'UID 200 is already taken.' >&2
        exit 1
    fi

    if [ -e /var/lib/java ]; then
        echo 'Cannot create $HOME for the java user.' >&2
        exit 1
    fi

    groupadd -g 200 -r java
     useradd -g 200 -u 200 -d /var/lib/java -s /sbin/nologin -r java
       mkdir -m 700 /var/lib/java

    {
        find /opt/java
        find /opt/java -type f \( -executable -o -name '*.so' \) -exec ldd {} \; \
            | sed -rn 's/^\s+(\S+ => \S+|\/lib\S+) \(0x[a-f0-9]+\)/\1/p' \
            | grep -Eo '/\S+' \
            | sort \
            | uniq \
            | xargs -I % -P $(nproc) find -L /lib* /usr/lib* -samefile %
        echo /etc/group
        echo /etc/passwd
        echo /tmp
        echo /var/lib/java
    } | rsync -av --files-from=- / /mnt
EOF

FROM scratch

COPY --from=0 /mnt /

WORKDIR /var/lib/java

USER 200:200

ENV JAVA_HOME=/opt/java
ENV PATH=$PATH:$JAVA_HOME/bin

ENTRYPOINT ["java"]
