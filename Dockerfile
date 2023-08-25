#
# Building stage
#
FROM maven:3.8.5-openjdk-17-slim AS builder
WORKDIR /app
COPY src ./src
COPY pom.xml ./
RUN mvn -f pom.xml clean package
#
# Base image creation stage
#
FROM alpine:latest AS base
RUN  apk update \
    && apk upgrade \
    && apk add ca-certificates \
    && update-ca-certificates \
    && echo http://dl-cdn.alpinelinux.org/alpine/v3.6/main >> /etc/apk/repositories \
    && echo http://dl-cdn.alpinelinux.org/alpine/v3.6/community >> /etc/apk/repositories \
    && apk add --update coreutils && rm -rf /var/cache/apk/*   \
    && apk add --update openjdk17-jre-headless \
    && apk add --no-cache nss \
    && rm -rf /var/cache/apk/*
#
# Packaging stage
#
FROM base
WORKDIR /app
COPY --from=builder /app/target/java-maven-app-*.jar ./
CMD java -jar ./java-maven-app-*.jar