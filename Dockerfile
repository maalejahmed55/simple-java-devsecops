FROM eclipse-temurin:17-jre

WORKDIR /app

# LIGNE CRITIQUE - utiliser le nom EXACT du fichier
COPY target/simple-java-devsecops-1.0.0.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]