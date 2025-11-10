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
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse SonarQube (méthode diagnostic)..."
                    
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            echo "🔧 Token length: \${#SONAR_TOKEN}"
                            
                            # 1. Vérification connexion avec token
                            echo "🔐 Test authentification..."
                            curl -u "\${SONAR_TOKEN}:" ${SONAR_HOST}/api/system/status
                            
                            # 2. Vérification si projet existe
                            echo "🔍 Recherche projet existant..."
                            curl -u "\${SONAR_TOKEN}:" "${SONAR_HOST}/api/projects/search?projects=${SONAR_PROJECT_KEY}" || echo "Projet non trouvé"
                            
                            # 3. ANALYSE SIMPLIFIÉE (comme dans le diagnostic)
                            echo "🚀 Lancement analyse Maven..."
                            mvn sonar:sonar \\
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \\
                            -Dsonar.sources=src \\
                            -Dsonar.java.binaries=target/classes \\
                            -Dsonar.host.url=${SONAR_HOST} \\
                            -Dsonar.token=\${SONAR_TOKEN}
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        echo "📸 Image créée:"
                        docker images | grep ${DOCKER_IMAGE} || echo "Aucune image trouvée"
                    """
                }
            }
        }
        
        stage('Security Scan - Trivy') {
            steps {
                script {
                    sh """
                        which trivy || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
                        echo "🔒 Scan Trivy..."
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                        trivy image --format json ${DOCKER_IMAGE}:${DOCKER_TAG} > trivy-report.json || echo "Rapport non généré"
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
                            echo "📦 Push Docker Hub..."
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
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
        }
        success {
            echo "🎉 SUCCÈS - SAST SonarQube terminé!"
        }
    }
}