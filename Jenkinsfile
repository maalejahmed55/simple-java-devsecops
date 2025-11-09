pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "votre-username-dockerhub"  // ⚠️ REMPLACEZ !
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    mvn clean package -DskipTests
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
                        # ⚠️ SANS SUDO - utilise les permissions Docker
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "📊 Images créées:"
                        docker images | grep ${DOCKER_IMAGE} || true
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Docker') {
            steps {
                script {
                    echo "🚀 Déploiement..."
                    sh """
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        docker run -d -p ${APP_PORT}:8080 --name ${APP_NAME} ${DOCKER_IMAGE}:latest
                        sleep 30
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Vérification..."
                    sh """
                        docker ps | grep ${APP_NAME} || echo "Container non trouvé"
                        curl -f http://localhost:${APP_PORT}/ || exit 1
                        echo "✅ Application déployée avec succès!"
                    """
                }
            }
        }
    }
}