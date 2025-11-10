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
        // ⬇️ CHOISIR UNE DES DEUX OPTIONS CI-DESSOUS ⬇️
        SONAR_TOKEN = "sqp_b0cf47f5c6a30692f381bbd3c0271121255e951d"  // OPTION 1: Token
        // SONAR_PASSWORD = "Futonahmed12$"  // OPTION 2: Mot de passe admin
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
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse SonarQube avec AUTHENTIFICATION..."
                    
                    // OPTION 1: AVEC TOKEN (Recommandé)
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                        -Dsonar.sources=src \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.token=${SONAR_TOKEN}
                    """
                    
                    // OU OPTION 2: AVEC LOGIN/MOT DE PASSE
                    // sh """
                    //     mvn sonar:sonar \
                    //     -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                    //     -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                    //     -Dsonar.sources=src \
                    //     -Dsonar.java.binaries=target/classes \
                    //     -Dsonar.sourceEncoding=UTF-8 \
                    //     -Dsonar.host.url=${SONAR_HOST} \
                    //     -Dsonar.login=admin \
                    //     -Dsonar.password=${SONAR_PASSWORD}
                    // """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction Docker..."
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
    }
    
    post {
        always {
            echo "📊 Build terminé"
            echo "🔗 SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"
        }
    }
}