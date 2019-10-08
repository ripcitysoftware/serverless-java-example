#!/usr/bin/env ash

JAVA_APP_JAR=${JAVA_APP_JAR:-app.jar}
JAVA_APP_PATH=${JAVA_APP_PATH:-/app}
JAVA_APP_JAR_PATH="${JAVA_APP_PATH}/${JAVA_APP_JAR}"
Xmx="${Xmx:-2048M}"
# we load the config from the JAR and then we load config from /app/config which will override
# application.properties
CONFIG_LOCATION="classpath:/application.properties,/app/conf/"
SPRING_CONFIG="--spring.config.location=${CONFIG_LOCATION}"

set -x

# See this page for why we are using these JVM options: https://hub.docker.com/_/openjdk/
JAVA_OPTIONS="                                   \
    -Xmx${Xmx}                                   \
    -XX:+UnlockExperimentalVMOptions             \
    -XX:+UseCGroupMemoryLimitForHeap"

# we expect the host env to provide an `application.properties` file to get service configuration
exec java ${JAVA_OPTIONS} -jar ${JAVA_APP_JAR_PATH} ${SPRING_CONFIG}
