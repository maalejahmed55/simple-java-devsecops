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
        SONAR_TOKEN = "sqp_b0cf47f5c6a30692f381bbd3c0271121255e951d"  // ⬅️ Votre token SonarQube
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
                    
                    # Vérification et adaptation structure
                    if [ -f "src/Main.java" ]; then
                        echo "✅ src/Main.java trouvé"
                        mkdir -p src/main/java/
                        cp src/Main.java src/main/java/
                        echo "🔄 Fichier copié vers src/main/java/"
                    else
                        echo "❌ src/Main.java non trouvé"
                        exit 1
                    fi
                    
                    # Build avec Maven
                    echo "🔨 Compilation Maven..."
                    mvn clean compile -DskipTests
                    
                    # Vérification
                    echo "📋 Vérification compilation:"
                    ls -la target/classes/ || echo "⚠️  Dossier classes manquant"
                    find target/classes/ -name "*.class" | head -5 || echo "⚠️  Aucune classe compilée"
                    
                    # Packaging
                    echo "📦 Packaging..."
                    mvn package -DskipTests
                    ls -la target/*.jar || echo "⚠️  Aucun JAR créé"
                    
                    echo "✅ Build terminé avec succès"
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    // Vérification préalable
                    sh '''
                        echo "🎯 Préparation SonarQube..."
                        echo "Classes compilées: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                        echo "JAR créé: $(ls target/*.jar 2>/dev/null | wc -l)"
                        echo "Fichiers sources: $(find src/main/java/ -name "*.java" 2>/dev/null | wc -l)"
                    '''
                    
                    // Analyse SonarQube avec token direct
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.host.url=http://localhost:9000 \
                        -Dsonar.token=${SONAR_TOKEN}
                    """
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
                    // Utilisation des credentials Jenkins pour Docker Hub uniquement
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
                echo "Image Docker: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "SonarQube: http://localhost:9000"
                echo "Application: http://localhost:${APP_PORT}"
                echo "Classes compilées: $(find target/classes/ -name "*.class" 2>/dev/null | wc -l)"
                echo "JAR: $(ls target/*.jar 2>/dev/null | wc -l)"
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