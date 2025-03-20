FROM alpine:3.21.3

ARG SOURCE_REPOSITORY=https://github.com/openjdk/jdk21u
ARG SOURCE_TAG=jdk-21.0.7+4

RUN echo "$SOURCE_REPOSITORY / $SOURCE_TAG" > version.txt
