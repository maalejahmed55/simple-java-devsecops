pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "maalejahmed"
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_PROJECT_KEY = "simple-java-devsecops"
        SONAR_PROJECT_NAME = "Simple Java DevSecOps"
        SONAR_HOST = "http://192.168.10.10:9000"
    }
    
    stages {
        stage('Checkout Git') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    if [ -f "src/Main.java" ]; then
                        echo "✅ src/Main.java trouvé"
                    else
                        echo "❌ src/Main.java non trouvé"
                        exit 1
                    fi
                    
                    mkdir -p target/classes/
                    javac -d target/classes/ src/Main.java
                    jar cfe target/simple-java-devsecops-1.0.0.jar Main -C target/classes/ .
                    
                    echo "📋 Fichiers générés:"
                    ls -la target/classes/
                    ls -la target/*.jar
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse SonarQube avec configuration DIRECTE..."
                    
                    // VERSION 1: Sans credentials (auth désactivée)
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                        -Dsonar.sources=src \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.host.url=${SONAR_HOST}
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        stage('Security Scan - Trivy') {
            steps {
                script {
                    sh """
                        which trivy || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                        trivy image --format json ${DOCKER_IMAGE}:${DOCKER_TAG} > trivy-report.json || true
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \"\${DOCKER_PASS}\" | docker login -u \"\${DOCKER_USER}\" --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Test') {
            steps {
                script {
                    sh """
                        docker stop ${APP_NAME}-test 2>/dev/null || true
                        docker rm ${APP_NAME}-test 2>/dev/null || true
                        docker run -d --name ${APP_NAME}-test -p ${APP_PORT}:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 10
                        curl -f http://localhost:${APP_PORT}/ || echo "⚠️  Application déployée"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Build terminé"
            echo "🔗 SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
        }
        success {
            echo "🎉 SUCCÈS - Pipeline terminé"
        }
        failure {
            echo "❌ ÉCHEC - Vérifiez les logs"
        }
    }
}