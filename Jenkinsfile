pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        DOCKER_USERNAME = "maalejahmed"
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_PROJECT_KEY = "simple-java-devsecops"
        SONAR_HOST = "http://192.168.10.10:9000"
    }
    
    stages {
        stage('Checkout') { steps { checkout scm } }
        
        stage('Build') {
            steps {
                sh '''
                    if [ -f "src/Main.java" ]; then
                        mkdir -p target/classes/
                        javac -d target/classes/ src/Main.java
                        jar cfe target/simple-java-devsecops-1.0.0.jar Main -C target/classes/ .
                        echo "✅ Build Java terminé"
                    fi
                    
                    # Vérification des dépendances
                    if [ -f "pom.xml" ]; then
                        echo "📦 Dépendances Maven détectées"
                        mvn dependency:tree || echo "⚠️  Pas de Maven"
                    else
                        echo "ℹ️  Aucune dépendance externe détectée"
                    fi
                '''
            }
        }
        
        stage('SAST - SonarQube') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            mvn sonar:sonar \\
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \\
                            -Dsonar.sources=src \\
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
                    echo "🔍 SCA: Analyse approfondie des dépendances Java..."
                    
                    sh '''
                        # Installation OWASP Dependency-Check
                        if [ ! -f "/usr/local/bin/dependency-check" ]; then
                            echo "📥 Installation OWASP Dependency-Check..."
                            wget -q https://github.com/jeremylong/DependencyCheck/releases/download/v9.0.10/dependency-check-9.0.10-release.zip
                            unzip -q dependency-check-9.0.10-release.zip -d /opt/
                            ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
                            echo "✅ OWASP Dependency-Check installé"
                        fi
                        
                        # Analyse SCA
                        mkdir -p reports/sca/
                        echo "🔎 Lancement analyse SCA..."
                        dependency-check.sh \
                            --project "simple-java-devsecops" \
                            --scan "." \
                            --out reports/sca/ \
                            --format HTML \
                            --format JSON \
                            --failOnCVSS 0 \
                            --enableExperimental
                        
                        echo "📊 Rapport SCA généré: reports/sca/dependency-check-report.html"
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    echo "🐳 Image Docker créée"
                """
            }
        }
        
        stage('Container Scan - Trivy') {
            steps {
                script {
                    echo "🔒 Scan de sécurité du container Docker..."
                    sh """
                        which trivy || curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        
                        # Scan de l'image Docker pour vulnérabilités OS
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Génération rapport
                        trivy image --format json --output reports/trivy-container-scan.json ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 DEVSECOPS TERMINÉ - Rapports:"
            echo "🔗 SAST (Code): ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"
            echo "📁 SCA (Dépendances): reports/sca/dependency-check-report.html"
            echo "🐳 Container Scan: reports/trivy-container-scan.json"
            
            archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
        }
        success {
            echo "🎉 PIPELINE DEVSECOPS RÉUSSI!"
            echo "✅ SAST, SCA et Container Scanning opérationnels"
        }
    }
}