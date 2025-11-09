pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "votre-username-dockerhub"
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    mvn clean package -DskipTests
                    echo "📦 Vérification des fichiers générés:"
                    ls -la target/
                    # Vérifier qu'un JAR existe
                    if ! ls target/*.jar 1> /dev/null 2>&1; then
                        echo "❌ ERREUR: Aucun fichier JAR créé!"
                        echo "🔍 Debug:"
                        find . -name "*.jar" -o -name "pom.xml"
                        exit 1
                    fi
                    echo "✅ Build réussi - JAR créé"
                '''
            }
        }
        
        stage('SAST - SmartCube Analysis') {
            steps {
                sh '''
                    echo "🔍 Analyse SAST avec SmartCube..."
                    # Votre commande existante
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        echo "🔍 Vérification pré-build:"
                        ls -la target/ || echo "Target non trouvé"
                        ls target/*.jar || echo "JAR non trouvé"
                        
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "✅ Image Docker créée"
                    """
                }
            }
        }
        
        // ... [les autres étapes restent identiques] ...
    }
}