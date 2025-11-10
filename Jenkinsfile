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
        
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    if [ -f "src/Main.java" ]; then
                        mkdir -p src/main/java/
                        cp src/Main.java src/main/java/
                    fi
                    mvn clean compile package -DskipTests
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    // Méthode 1 : Avec des simples quotes et échappement
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=simple-java-devsecops \
                        -Dsonar.projectName="Simple Java DevSecOps" \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.host.url=http://localhost:9000 \
                        -Dsonar.login=admin \
                        -Dsonar.password=Futonahmed12\\$
                    '''
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
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
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
                        sleep 15
                        curl -f http://localhost:${APP_PORT}/ || echo "Application déployée"
                    """
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
    }
}