FROM alpine:3.21.3

ARG source_repository=https://github.com/openjdk/jdk21u
ARG source_tag=jdk-21.0.7+4

RUN echo "$source_repository / $source_tag" > version.txt
