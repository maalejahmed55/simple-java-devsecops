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
        stage('Checkout Git') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "✅ Image créée"
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \${DOCKER_PASS} | docker login -u \${DOCKER_USER} --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            echo "✅ Images poussées"
                        """
                    }
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo "🚀 Déploiement..."
                    sh """
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        docker run -d -p ${APP_PORT}:8080 --name ${APP_NAME} ${DOCKER_IMAGE}:latest
                        echo "🎯 Container démarré"
                        echo "ℹ️  Health check désactivé - vérifiez manuellement avec: docker logs ${APP_NAME}"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ PIPELINE TERMINÉ"
            echo "🔍 Vérifiez manuellement: docker logs ${APP_NAME}"
        }
        failure {
            echo "❌ PIPELINE ÉCHOUÉ"
        }
    }
}