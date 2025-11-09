pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "maalejahmed"
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        // ÉTAPE 1 : Checkout du code
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // ÉTAPE 2 : Build Docker (fait TOUT le travail)
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction COMPLÈTE dans Docker..."
                    sh """
                        echo "📁 Fichiers disponibles:"
                        ls -la
                        echo "🏗️ Lancement du build Docker (inclut le build Maven)..."
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        echo "✅ Image Docker créée!"
                    """
                }
            }
        }
        
        // ÉTAPE 3 : Push vers Docker Hub
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
                            echo "✅ Images poussées sur Docker Hub!"
                        """
                    }
                }
            }
        }
        
        // ÉTAPE 4 : Déploiement
        stage('Deploy') {
            steps {
                script {
                    echo "🚀 Déploiement de l'application..."
                    sh """
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        docker run -d -p ${APP_PORT}:8080 --name ${APP_NAME} ${DOCKER_IMAGE}:latest
                        echo "⏳ Attente du démarrage..."
                        sleep 30
                    """
                }
            }
        }
        
        // ÉTAPE 5 : Vérification
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Vérification du déploiement..."
                    sh """
                        if curl -s -f http://localhost:${APP_PORT}/ > /dev/null; then
                            echo "🎉 SUCCÈS : Application déployée et accessible!"
                            echo "🌐 URL : http://localhost:${APP_PORT}/"
                        else
                            echo "❌ ERREUR : L'application ne répond pas"
                            echo "🔍 Logs du container:"
                            docker logs ${APP_NAME} --tail 20
                            exit 1
                        fi
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Pipeline terminé"
        }
        success {
            echo "✅ DÉPLOIEMENT RÉUSSI!"
        }
        failure {
            echo "❌ Échec du déploiement"
        }
    }
}