FROM alpine:3.21.0

RUN apk add git

ARG jdk_updates_release
ARG jdk_updates_tag

RUN git clone $jdk_updates_release -b $jdk_updates_tag --depth 1
