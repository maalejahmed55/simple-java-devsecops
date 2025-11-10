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
    }
    
    stages {
        stage('Checkout Git') {
            steps {
                checkout scm
            }
        }
        
        stage('Build et Tests') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application avec Maven..."
                    echo "📁 Structure du projet:"
                    ls -la
                    
                    # Build avec Maven (crée le JAR pour Docker et SonarQube)
                    mvn clean compile
                    mvn test
                    
                    # Vérification
                    echo "📋 Fichiers générés:"
                    ls -la target/
                    find target/ -name "*.jar" | head -5
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.host.url=http://localhost:9000 \
                            -Dsonar.login=admin \
                            -Dsonar.password=admin
                        """
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
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
                    echo "🔒 Scan de sécurité avec Trivy..."
                    sh """
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                        trivy image --format json ${DOCKER_IMAGE}:${DOCKER_TAG} > trivy-report.json || true
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📦 Push vers Docker Hub..."
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
                    echo "🚀 Déploiement en environnement de test..."
                    sh """
                        docker stop ${APP_NAME}-test 2>/dev/null || true
                        docker rm ${APP_NAME}-test 2>/dev/null || true
                        
                        docker run -d \
                            --name ${APP_NAME}-test \
                            -p ${APP_PORT}:8080 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        sleep 15
                        
                        # Health check
                        curl -f http://localhost:${APP_PORT}/ || \
                        curl -f http://localhost:${APP_PORT}/health || \
                        echo "⚠️  Application déployée"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Build ${APP_NAME} terminé"
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
        }
    }
}