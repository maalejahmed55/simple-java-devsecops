# Dockerfile corrigé
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copier le JAR directement (le build se fait avant dans Jenkins)
COPY target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]