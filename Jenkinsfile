pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_REGISTRY = "docker.io"  // ou votre registry
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
        
        stage('Checkout') {
            steps {
                sh '''
                    echo "📁 Préparation des fichiers..."
                    ls -la
                    echo "🐳 Vérification de Docker..."
                    docker --version
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    mvn clean package -DskipTests
                    echo "📦 Fichiers générés:"
                    ls -la target/
                '''
            }
        }
        
        stage('SAST - SmartCube Analysis') {
            steps {
                sh '''
                    echo "🔍 Analyse SAST avec SmartCube..."
                    # Votre commande SmartCube existante ici
                    echo "✅ Analyse sécurité terminée"
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    echo "🧪 Exécution des tests..."
                    mvn test
                    echo "✅ Tests terminés"
                '''
            }
        }
        
        // 🆕 ÉTAPE AJOUTÉE : Build Docker Image avec tags
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "📊 Images Docker créées:"
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        // 🆕 ÉTAPE AJOUTÉE : Push vers Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi de l'image vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',  // ← À créer dans Jenkins
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "🔐 Authentification à Docker Hub..."
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            echo "🚀 Pushing images to Docker Hub..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            
                            echo "✅ Images pushed successfully!"
                        """
                    }
                }
            }
        }
        
        // ÉTAPE MODIFIÉE : Déploiement depuis Docker Hub
        stage('Deploy to Docker') {
            steps {
                script {
                    echo "🚀 Déploiement de l'application depuis Docker Hub..."
                    sh """
                        echo "🧹 Nettoyage des anciens containers..."
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        
                        # 🆕 Pull de l'image depuis Docker Hub au lieu de l'image locale
                        echo "📥 Téléchargement de l'image depuis Docker Hub..."
                        docker pull ${DOCKER_IMAGE}:latest
                        
                        echo "🎯 Démarrage du nouveau container..."
                        docker run -d \\
                            -p ${APP_PORT}:8080 \\
                            --name ${APP_NAME} \\
                            ${DOCKER_IMAGE}:latest
                        
                        echo "⏳ Attente du démarrage (30 secondes)..."
                        sleep 30
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Vérification du déploiement..."
                    sh """
                        echo "📊 Statut du container:"
                        docker ps | grep ${APP_NAME} || echo "❌ Container non trouvé"
                        
                        echo "🌐 Test de l'application..."
                        curl -f http://localhost:${APP_PORT}/ || exit 1
                        
                        echo "📋 Derniers logs:"
                        docker logs ${APP_NAME} --tail 10
                        
                        echo "✅ Santé de l'application vérifiée!"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Nettoyage des ressources..."
            sh '''
                echo "🧹 Nettoyage Docker..."
                docker system prune -f || true
                
                echo "🏷️ Images disponibles sur Docker Hub:"
                echo "  - ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "  - ${DOCKER_IMAGE}:latest"
            '''
        }
        success {
            echo "✅ Déploiement réussi!"
            echo "🌐 Application: http://localhost:${APP_PORT}"
            echo "🐳 Images disponibles sur Docker Hub"
        }
        failure {
            echo "❌ Échec du déploiement"
        }
    }
}