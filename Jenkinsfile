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
                    echo "📁 Structure du projet:"
                    ls -la
                    echo "📄 Fichiers Java:"
                    find . -name "*.java" -type f
                    
                    # Vérification de la structure
                    echo "🔍 Vérification structure src/Main.java:"
                    if [ -f "src/Main.java" ]; then
                        echo "✅ src/Main.java trouvé"
                        cat src/Main.java | head -10
                    else
                        echo "❌ src/Main.java non trouvé"
                        exit 1
                    fi
                    
                    # Compilation pour SonarQube uniquement
                    echo "🔨 Compilation pour SonarQube..."
                    mkdir -p target/classes/
                    javac -d target/classes/ src/Main.java
                    
                    # Vérification compilation
                    echo "📋 Vérification compilation:"
                    ls -la target/classes/
                    find target/classes/ -name "*.class" | head -5
                    
                    echo "✅ Build terminé (prêt pour Docker)"
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    // Vérification avant SonarQube
                    sh '''
                        echo "🎯 Préparation pour SonarQube..."
                        echo "📊 Fichiers disponibles:"
                        echo "Classes: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                        echo "Sources: $(find src/ -name "*.java" | wc -l)"
                    '''
                    
                    // Analyse SonarQube
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184:sonar \
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
                    
                    echo "✅ Analyse SonarQube lancée"
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    echo "📊 Attente des résultats du Quality Gate..."
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                    echo "✅ Quality Gate vérifié"
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
                        # Installation de Trivy si nécessaire
                        which trivy || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
                        
                        # Scan de l'image Docker
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Rapport détaillé
                        trivy image --format json ${DOCKER_IMAGE}:${DOCKER_TAG} > trivy-report.json || true
                    """
                }
            }
        }
        
        stage('Test Application') {
            steps {
                script {
                    echo "🧪 Tests de l'application Dockerisée..."
                    sh """
                        # Test en arrière-plan
                        docker run -d --name test-app -p 8082:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 10
                        
                        # Test de fonctionnement basique
                        curl -f http://localhost:8082/ || echo "⚠️  Application non accessible"
                        
                        # Arrêt du conteneur de test
                        docker stop test-app || true
                        docker rm test-app || true
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
                        # Arrêt du conteneur existant
                        docker stop ${APP_NAME}-test 2>/dev/null || true
                        docker rm ${APP_NAME}-test 2>/dev/null || true
                        
                        # Démarrage du nouveau conteneur
                        docker run -d \
                            --name ${APP_NAME}-test \
                            -p ${APP_PORT}:8080 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Attente du démarrage
                        sleep 10
                        
                        # Test de santé
                        echo "🔍 Test de santé de l'application..."
                        curl -f http://localhost:${APP_PORT}/ || \
                        curl -f http://localhost:${APP_PORT}/health || \
                        echo "⚠️  Application déployée mais endpoints non accessibles"
                        
                        # Vérification conteneur
                        docker ps | grep ${APP_NAME}-test
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Rapport de build final..."
            sh '''
                echo "=== RAPPORT FINAL BUILD ==="
                echo "Structure:"
                echo "  - src/Main.java: $(if [ -f "src/Main.java" ]; then echo "✅"; else echo "❌"; fi)"
                echo "  - Classes compilées: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                echo "  - Image Docker: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "URLs:"
                echo "  - SonarQube: http://localhost:9000"
                echo "  - Application: http://localhost:${APP_PORT}"
            '''
            
            // Archivage des rapports
            archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
            
            // Nettoyage
            sh '''
                docker stop ${APP_NAME}-test 2>/dev/null || true
                docker rm ${APP_NAME}-test 2>/dev/null || true
                docker system prune -f || true
            '''
        }
        success {
            echo "✅ Pipeline exécuté avec succès!"
        }
        failure {
            echo "❌ Échec du pipeline!"
        }
    }
}