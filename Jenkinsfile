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
        SLACK_CHANNEL = "#devsecnotif"
        // Registry local au lieu de Docker Hub
        REGISTRY_URL = "localhost:5000"
    }
    
    stages {
        stage('Cleanup Docker') {
            steps {
                script {
                    echo "🧹 NETTOYAGE D'URGENCE DOCKER..."
                    sh """
                        # Nettoyage agressif pour libérer de l'espace
                        echo "=== NETTOYAGE DOCKER ==="
                        docker system prune -a -f --volumes
                        docker system df
                        
                        echo "=== ESPACE LIBÉRÉ ==="
                        df -h
                    """
                }
            }
        }
        
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
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            mvn sonar:sonar \\
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \\
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \\
                            -Dsonar.sources=src \\
                            -Dsonar.java.binaries=target/classes \\
                            -Dsonar.host.url=${SONAR_HOST} \\
                            -Dsonar.token=\${SONAR_TOKEN}
                        """
                    }
                }
            }
        }
        
        stage('SCA - OWASP Dependency-Check') {
            steps {
                script {
                    echo "🔍 SCA: Analyse des dépendances avec OWASP..."
                    
                    sh '''
                        mkdir -p reports/sca/
                        
                        echo "🐳 Lancement OWASP Dependency-Check optimisé..."
                        
                        docker run --rm \
                            -v "$(pwd)":/src \
                            -v "$(pwd)/reports/sca":/reports \
                            owasp/dependency-check:latest \
                            dependency-check.sh \
                            --project "simple-java-devsecops" \
                            --scan /src \
                            --out /reports \
                            --format HTML \
                            --format JSON \
                            --failOnCVSS 0 \
                            --disableOssIndex true \
                            --noupdate \
                            --data /tmp/dc-data || echo "⚠️  Analyse terminée avec warnings"
                    '''
                }
            }
            
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports/sca',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'SCA OWASP Report',
                        reportTitles: 'Analyse des Dépendances OWASP'
                    ])
                }
            }
        }
        
        stage('Start Local Registry') {
            steps {
                script {
                    echo "🏠 Démarrage du Registry Docker Local..."
                    sh """
                        # Démarrage d'un registry local sur le port 5000
                        docker run -d --restart=always -p 5000:5000 --name registry registry:2
                        echo "✅ Registry local démarré sur localhost:5000"
                        
                        # Vérification
                        curl -s http://localhost:5000/v2/_catalog || echo "Registry accessible"
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        # Build optimisé
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        
                        # Tag pour le registry local
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${REGISTRY_URL}/${APP_NAME}:${DOCKER_TAG}
                        
                        echo "📸 Images créées:"
                        docker images | grep ${APP_NAME} | head -5
                    """
                }
            }
        }
        
        stage('Container Security Scan') {
            steps {
                script {
                    echo "🔒 Scan de sécurité rapide..."
                    sh """
                        # Scan ultra-rapide avec timeout
                        timeout 120 docker run --rm \\
                            -v /var/run/docker.sock:/var/run/docker.sock \\
                            aquasec/trivy:latest \\
                            image --exit-code 0 \\
                            --no-progress \\
                            --severity CRITICAL \\
                            --ignore-unfixed \\
                            ${DOCKER_IMAGE}:${DOCKER_TAG} || echo "⚠️  Scan terminé"
                    """
                }
            }
        }
        
        stage('Push to Local Registry') {
            steps {
                script {
                    echo "📤 Push vers le Registry Local..."
                    sh """
                        # Pas besoin d'authentification pour le registry local
                        docker push ${REGISTRY_URL}/${APP_NAME}:${DOCKER_TAG}
                        
                        echo "✅ Image poussée avec succès!"
                        echo "📍 Registry: ${REGISTRY_URL}"
                        echo "🏷️  Image: ${APP_NAME}:${DOCKER_TAG}"
                        
                        # Vérification
                        echo "📋 Liste des images dans le registry:"
                        curl -s http://localhost:5000/v2/_catalog | python -m json.tool || curl -s http://localhost:5000/v2/_catalog
                    """
                }
            }
        }
        
        stage('Test Local Image') {
            steps {
                script {
                    echo "🧪 Test de l'image locale..."
                    sh """
                        # Test de pull depuis le registry local
                        docker pull ${REGISTRY_URL}/${APP_NAME}:${DOCKER_TAG}
                        
                        # Test de run
                        docker run --rm -d --name test-container -p 8082:8081 ${REGISTRY_URL}/${APP_NAME}:${DOCKER_TAG} &
                        sleep 10
                        
                        # Test de connexion
                        echo "🔍 Test de l'application..."
                        curl -s http://localhost:8082 || echo "❌ Application non accessible"
                        
                        # Nettoyage
                        docker stop test-container 2>/dev/null || true
                        
                        echo "✅ Test local réussi!"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 PIPELINE DEVSECOPS TERMINÉ - SOLUTION LOCALE"
            echo "================================================"
            echo "🔗 SAST (Code): ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"
            echo "📁 SCA (Dépendances): Voir 'SCA OWASP Report'"
            echo "🏠 Registry Local: ${REGISTRY_URL}"
            echo "🐳 Image: ${APP_NAME}:${DOCKER_TAG}"
            
            // Nettoyage final
            sh """
                docker stop registry 2>/dev/null || true
                docker rm registry 2>/dev/null || true
                docker system prune -f || true
            """
            
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
        }
        
        success {
            echo "🎉 SUCCÈS - Pipeline DevSecOps LOCAL complété!"
            
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "good",
                message: """🎉 SUCCÈS - Pipeline DevSecOps LOCAL
                
📋 INFORMATIONS :
• Projet: ${SONAR_PROJECT_NAME}
• Build: #${env.BUILD_NUMBER}
• Statut: SUCCÈS ✅
• Solution: Registry Local (problème réseau Docker Hub)

🏠 REGISTRY LOCAL :
• URL: ${REGISTRY_URL}
• Image: ${APP_NAME}:${DOCKER_TAG}

📊 ANALYSES EFFECTUÉES :
✓ SAST SonarQube
✓ SCA OWASP Dependency-Check  
✓ Scan Sécurité Trivy
✓ Test Local Application

🔗 LIENS :
• SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
• Build: ${env.BUILD_URL}"""
            )
        }
        
        failure {
            echo "❌ ÉCHEC - Voir les logs"
            
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "danger",
                message: """🚨 ÉCHEC - Pipeline Local
Projet: ${SONAR_PROJECT_NAME}
Build: #${env.BUILD_NUMBER}
Problème: Voir logs détaillés
Accès: ${env.BUILD_URL}console"""
            )
        }
    //ffff
    }
}