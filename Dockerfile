FROM alpine:3.21.1

# renovate: datasource=github-tags depName=openjdk/jdk17u versioning=regex:^jdk-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\+(?<build>\d+)$
ARG JDK_UPDATES_TAG=jdk-17.0.13+7
