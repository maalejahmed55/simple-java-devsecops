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
        
        stage('Debug Structure') {
            steps {
                sh '''
                    echo "🔍 DEBUG - Structure du projet:"
                    echo "=== Fichiers Java trouvés ==="
                    find . -name "*.java" -type f
                    echo "=== Contenu racine ==="
                    ls -la
                    echo "=== Contenu src/ ==="
                    ls -la src/
                '''
            }
        }
        
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    
                    # Vérification du fichier source
                    if [ -f "src/Main.java" ]; then
                        echo "✅ src/Main.java trouvé"
                        echo "📄 Contenu du fichier (premières lignes):"
                        head -20 src/Main.java || echo "Impossible de lire le fichier"
                    else
                        echo "❌ Fichier src/Main.java non trouvé"
                        echo "📁 Contenu du dossier src/:"
                        ls -la src/ || echo "Dossier src/ inexistant"
                        exit 1
                    fi
                    
                    # Compilation directe depuis src/Main.java
                    echo "🔨 Compilation..."
                    mkdir -p target/classes/
                    javac -d target/classes/ src/Main.java
                    
                    # Vérification compilation
                    echo "📋 Résultats compilation:"
                    ls -la target/classes/ || echo "❌ Aucune classe compilée"
                    find target/classes/ -name "*.class" | head -5 || echo "❌ Aucun fichier .class"
                    
                    # Création du JAR pour Docker
                    echo "📦 Création du JAR..."
                    jar cfe target/simple-java-devsecops-1.0.0.jar Main -C target/classes/ .
                    ls -la target/*.jar || echo "❌ Aucun JAR créé"
                    
                    echo "✅ Build terminé avec succès"
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    // Vérification finale avant analyse
                    sh '''
                        echo "🎯 Préparation SonarQube..."
                        echo "Fichier source: $(ls -la src/Main.java 2>/dev/null | wc -l)"
                        echo "Classes compilées: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                        echo "JAR: $(ls target/*.jar 2>/dev/null | wc -l)"
                    '''
                    
                    // Analyse DIRECTE de src/Main.java
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.java.libraries=target/*.jar
                        """
                    }
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
                        echo "📸 Images Docker créées:"
                        docker images | grep ${DOCKER_IMAGE} || echo "⚠️  Aucune image trouvée"
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
                        echo "🔍 Scan des vulnérabilités..."
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Rapport détaillé
                        trivy image --format json ${DOCKER_IMAGE}:${DOCKER_TAG} > trivy-report.json || echo "⚠️  Rapport Trivy non généré"
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
                            echo "🚀 Push de l'image..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_IMAGE}:latest
                            echo "✅ Images poussées avec succès vers Docker Hub"
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
                        # Nettoyage des anciens conteneurs
                        echo "🧹 Nettoyage des conteneurs existants..."
                        docker stop ${APP_NAME}-test 2>/dev/null || true
                        docker rm ${APP_NAME}-test 2>/dev/null || true
                        
                        # Démarrage du nouveau conteneur
                        echo "🎯 Démarrage du conteneur..."
                        docker run -d \
                            --name ${APP_NAME}-test \
                            -p ${APP_PORT}:8080 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Attente du démarrage
                        echo "⏳ Attente du démarrage de l'application..."
                        sleep 15
                        
                        # Test de santé
                        echo "🔍 Test de santé de l'application..."
                        curl -f http://localhost:${APP_PORT}/ || \
                        curl -f http://localhost:${APP_PORT}/health || \
                        echo "⚠️  Application déployée mais endpoints non accessibles"
                        
                        # Vérification finale
                        echo "✅ Conteneur en cours d'exécution:"
                        docker ps | grep ${APP_NAME}-test || echo "⚠️  Conteneur non trouvé"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Rapport de build final..."
            sh '''
                echo "=== RAPPORT FINAL ==="
                echo "Projet: ${SONAR_PROJECT_NAME}"
                echo "Build: ${BUILD_NUMBER}"
                echo "Fichier analysé: src/Main.java"
                echo "Classes compilées: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                echo "JAR: $(ls target/*.jar 2>/dev/null | wc -l)"
                echo "Image Docker: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "SonarQube: http://192.168.10.10:9000/dashboard?id=${SONAR_PROJECT_KEY}"
                echo "Application: http://localhost:${APP_PORT}"
            '''
            
            // Archivage des artefacts
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
            
            // Nettoyage
            sh '''
                echo "🧹 Nettoyage des ressources..."
                docker stop ${APP_NAME}-test 2>/dev/null || true
                docker rm ${APP_NAME}-test 2>/dev/null || true
            '''
        }
        success {
            echo "🎉 PIPELINE RÉUSSI !"
        }
        failure {
            echo "❌ PIPELINE EN ÉCHEC"
        }
    }
}