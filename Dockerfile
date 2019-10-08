FROM gradle:4.9-jdk8 AS builder

COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle clean build -x test


FROM openjdk:8-jre-alpine
EXPOSE 8081
COPY --from=builder /home/gradle/src/build/libs/*.jar /app/app.jar
RUN mkdir -p /app/conf
WORKDIR /app
COPY startup.sh /app
RUN chmod 755 /app/startup.sh

HEALTHCHECK --interval=5m --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:8081/actuator/health || exit 1

ENTRYPOINT /app/startup.sh

