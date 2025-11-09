# Étape 1 : Build de l'application
FROM maven:3.8.4-openjdk-17 AS builder

WORKDIR /app

# Copier les fichiers du projet
COPY pom.xml .
COPY src ./src

# Builder l'application
RUN mvn clean package -DskipTests

# Étape 2 : Image finale
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copier seulement le JAR depuis l'étape de build
COPY --from=builder /app/target/simple-java-devsecops-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]