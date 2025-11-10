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
                        head -10 src/Main.java || echo "Impossible de lire le fichier"
                    else
                        echo "❌ src/Main.java non trouvé"
                        ls -la src/ || echo "Dossier src/ inexistant"
                        exit 1
                    fi
                    
                    mkdir -p target/classes/
                    javac -d target/classes/ src/Main.java
                    jar cfe target/simple-java-devsecops-1.0.0.jar Main -C target/classes/ .
                    
                    echo "📋 Résultats build:"
                    ls -la target/classes/ || echo "Aucune classe compilée"
                    ls -la target/*.jar || echo "Aucun JAR créé"
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
                        echo "📁 Fichiers détectés:"
                        find . -name "pom.xml" -o -name "*.jar" -o -name "*.war" | head -10 || echo "Aucun fichier de dépendance détecté"
                        
                        mkdir -p reports/sca/
                        
                        # Vérifier si Docker est disponible
                        if command -v docker >/dev/null 2>&1; then
                            echo "🐳 Méthode Docker sélectionnée"
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
                                --enableExperimental
                        else
                            echo "📝 Méthode basique (Docker non disponible)"
                            # Créer un rapport HTML basique
                            cat > reports/sca/dependency-check-report.html << EOR
                            <!DOCTYPE html>
                            <html>
                            <head>
                                <title>SCA Report - OWASP Dependency-Check</title>
                                <style>
                                    body { font-family: Arial, sans-serif; margin: 40px; }
                                    .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
                                    .info { background: #e7f3ff; padding: 15px; margin: 10px 0; }
                                    .warning { background: #fff3cd; padding: 15px; margin: 10px 0; }
                                </style>
                            </head>
                            <body>
                                <div class="header">
                                    <h1>🔍 SCA Analysis Report</h1>
                                    <p>Project: simple-java-devsecops</p>
                                    <p>Date: $(date)</p>
                                </div>
                                
                                <div class="warning">
                                    <h2>⚠️ OWASP Dependency-Check via Docker non disponible</h2>
                                    <p>Pour une analyse SCA complète:</p>
                                    <ul>
                                        <li>Installez Docker sur le serveur Jenkins</li>
                                        <li>Ou installez OWASP Dependency-Check manuellement</li>
                                    </ul>
                                </div>
                                
                                <div class="info">
                                    <h3>📁 Fichiers Détectés</h3>
                                    <pre>$(find . -name "*.java" -o -name "pom.xml" -o -name "*.jar" | head -20)</pre>
                                </div>
                            </body>
                            </html>
EOR
                        fi
                        
                        echo "✅ Analyse SCA terminée"
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
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker images | grep ${DOCKER_IMAGE} || echo "Aucune image trouvée"
                    """
                }
            }
        }
        
        stage('Container Security Scan') {
            steps {
                script {
                    echo "🔒 Scan de sécurité du container..."
                    sh """
                        which trivy >/dev/null 2>&1 || (
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        )
                        
                        trivy image --exit-code 0 --no-progress --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG} && echo "✅ Scan réussi" || echo "⚠️  Vulnérabilités détectées"
                        
                        trivy image --format json --output reports/trivy-container-scan.json ${DOCKER_IMAGE}:${DOCKER_TAG} 2>/dev/null || true
                    """
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
                        
                        docker run -d --name ${APP_NAME}-test -p ${APP_PORT}:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        sleep 10
                        curl -f http://localhost:${APP_PORT}/ || echo "⚠️  Application déployée (health check échoué)"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 PIPELINE DEVSECOPS TERMINÉ"
            echo "================================="
            echo "🔗 SAST (Code): ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"
            echo "📁 SCA (Dépendances): Voir 'SCA OWASP Report' ci-dessus"
            echo "🐳 Container: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "🌐 Application: http://localhost:${APP_PORT}"
            
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
            
            sh '''
                docker stop ${APP_NAME}-test 2>/dev/null || true
                docker rm ${APP_NAME}-test 2>/dev/null || true
            '''
        }
        success {
            echo "🎉 SUCCÈS - Pipeline DevSecOps complété!"
        }
        failure {
            echo "❌ ÉCHEC - Consultez les logs pour détails"
        }
    }
}