# Version minimaliste garantie
FROM alpine:3.18

# Installation manuelle de Java
RUN apk add --no-cache openjdk17-jre

WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
# Fin du Dockerfile