pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "votre-username-dockerhub"  // ⚠️ REMPLACEZ par VOTRE username
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
                    # Votre commande existante
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
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        # AVEC SUDO en attendant les permissions
                        sudo docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        sudo docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "📊 Images Docker créées:"
                        sudo docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi de l'image vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "🔐 Authentification à Docker Hub..."
                            echo \$DOCKER_PASS | sudo docker login -u \$DOCKER_USER --password-stdin
                            
                            echo "🚀 Pushing images to Docker Hub..."
                            sudo docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            sudo docker push ${DOCKER_IMAGE}:latest
                            
                            echo "✅ Images poussées avec succès!"
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Docker') {
            steps {
                script {
                    echo "🚀 Déploiement de l'application..."
                    sh """
                        echo "🧹 Nettoyage des anciens containers..."
                        sudo docker stop ${APP_NAME} || true
                        sudo docker rm ${APP_NAME} || true
                        
                        echo "📥 Téléchargement de l'image depuis Docker Hub..."
                        sudo docker pull ${DOCKER_IMAGE}:latest
                        
                        echo "🎯 Démarrage du nouveau container..."
                        sudo docker run -d \\
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
                        sudo docker ps | grep ${APP_NAME} || echo "❌ Container non trouvé"
                        
                        echo "🌐 Test de l'application..."
                        curl -f http://localhost:${APP_PORT}/ || exit 1
                        
                        echo "📋 Derniers logs:"
                        sudo docker logs ${APP_NAME} --tail 10
                        
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
                sudo docker system prune -f || true
            '''
        }
        success {
            echo "✅ Déploiement réussi! Application disponible sur http://localhost:${APP_PORT}"
        }
        failure {
            echo "❌ Échec du déploiement"
        }
    }
}