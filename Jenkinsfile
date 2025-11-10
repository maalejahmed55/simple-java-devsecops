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
                    echo "📄 Fichiers Java disponibles:"
                    find . -name "*.java" -type f
                    
                    # Vérification spécifique
                    echo "🔍 Vérification de src/Main.java:"
                    if [ -f "src/Main.java" ]; then
                        echo "✅ src/Main.java trouvé"
                        # Afficher les premières lignes pour debug
                        head -20 src/Main.java
                    else
                        echo "❌ Fichier src/Main.java non trouvé"
                        exit 1
                    fi
                    
                    # Création de la structure temporaire pour Maven
                    echo "🔄 Adaptation pour Maven..."
                    mkdir -p src/main/java/
                    cp src/Main.java src/main/java/
                    
                    # Build avec Maven
                    echo "🔨 Compilation Maven..."
                    mvn clean compile -DskipTests
                    
                    # Vérification des résultats
                    echo "📋 Résultats de compilation:"
                    ls -la target/ || echo "⚠️  Dossier target non créé"
                    find target/ -name "*.class" 2>/dev/null | head -5 || echo "⚠️  Aucune classe compilée"
                    
                    # Packaging
                    echo "📦 Packaging..."
                    mvn package -DskipTests
                    ls -la target/*.jar || echo "⚠️  Aucun JAR créé"
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    sh '''
                        echo "🎯 Préparation SonarQube..."
                        echo "Classes compilées: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                        echo "JAR: $(ls target/*.jar 2>/dev/null | wc -l)"
                    '''
                    
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                            -Dsonar.sources=src/main/java \
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
                    echo "📊 Attente du Quality Gate..."
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction image Docker..."
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
                    echo "🔒 Scan sécurité avec Trivy..."
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
                    echo "🚀 Déploiement test..."
                    sh """
                        docker stop ${APP_NAME}-test 2>/dev/null || true
                        docker rm ${APP_NAME}-test 2>/dev/null || true
                        
                        docker run -d \
                            --name ${APP_NAME}-test \
                            -p ${APP_PORT}:8080 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        sleep 15
                        curl -f http://localhost:${APP_PORT}/ || echo "⚠️  Application déployée"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Rapport final..."
            sh '''
                echo "=== RAPPORT ==="
                echo "Structure: src/Main.java → $(if [ -f "src/Main.java" ]; then echo "✅"; else echo "❌"; fi)"
                echo "Classes: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                echo "JAR: $(ls target/*.jar 2>/dev/null | wc -l)"
                echo "Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            '''
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
        }
    }
}