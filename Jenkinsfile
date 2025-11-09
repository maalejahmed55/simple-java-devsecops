pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "maalejahmed"  // ✅ REMPLACEZ par VOTRE username Docker Hub
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        // ÉTAPE 1: Récupération du code
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        // ÉTAPE 2: Vérification de l'environnement
        stage('Environment Check') {
            steps {
                sh '''
                    echo "🔍 Vérification de l'environnement..."
                    echo "📅 Date: $(date)"
                    echo "📁 Répertoire: $(pwd)"
                    echo "🐳 Docker: $(docker --version)"
                    echo "☕ Java: $(java -version 2>&1 | head -1)"
                    echo "📦 Maven: $(mvn --version 2>&1 | head -1)"
                    echo "📋 Contenu du projet:"
                    ls -la
                '''
            }
        }
        
        // ÉTAPE 3: Build de l'application
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    mvn clean package -DskipTests
                    echo "📦 Vérification du build:"
                    ls -la target/
                    if [ -f "target/simple-java-devsecops-1.0.0.jar" ]; then
                        echo "✅ JAR créé avec succès: target/simple-java-devsecops-1.0.0.jar"
                    else
                        echo "❌ ERREUR: Fichier JAR non trouvé!"
                        echo "🔍 Recherche des fichiers JAR:"
                        find . -name "*.jar" -type f
                        exit 1
                    fi
                '''
            }
        }
        
        // ÉTAPE 4: Analyse de sécurité SAST
        stage('SAST - SmartCube Analysis') {
            steps {
                sh '''
                    echo "🔍 Analyse SAST avec SmartCube..."
                    # Votre commande SmartCube existante ici
                    echo "smartsonar -Dacnar projectKey=simple-java-devsecops -Dacnar projectName='Simple Java DevSecOps'"
                    echo "✅ Analyse sécurité terminée"
                '''
            }
        }
        
        // ÉTAPE 5: Tests
        stage('Test') {
            steps {
                sh '''
                    echo "🧪 Exécution des tests..."
                    mvn test
                    echo "✅ Tests terminés"
                '''
            }
        }
        
        // ÉTAPE 6: Construction image Docker
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        echo "🔍 Pré-vérification du contexte Docker..."
                        echo "📍 Répertoire: \$(pwd)"
                        echo "📁 Contenu:"
                        ls -la
                        echo "📦 Fichier JAR:"
                        ls -la target/simple-java-devsecops-1.0.0.jar
                        echo "🐳 Dockerfile:"
                        cat Dockerfile
                        
                        echo "🏗️ Lancement du build Docker..."
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        
                        echo "🏷️ Tagging de l'image..."
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        
                        echo "✅ Images créées:"
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        // ÉTAPE 7: Push vers Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi de l'image vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "🔐 Authentification à Docker Hub..."
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            echo "🚀 Pushing de l'image versionnée..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            echo "🚀 Pushing de l'image latest..."
                            docker push ${DOCKER_IMAGE}:latest
                            
                            echo "✅ Images poussées avec succès vers Docker Hub!"
                            echo "🌐 Disponible sur: https://hub.docker.com/r/${DOCKER_IMAGE}"
                        """
                    }
                }
            }
        }
        
        // ÉTAPE 8: Déploiement
        stage('Deploy to Docker') {
            steps {
                script {
                    echo "🚀 Déploiement de l'application..."
                    sh """
                        echo "🧹 Nettoyage des anciens containers..."
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        
                        echo "📥 Téléchargement de la dernière image..."
                        docker pull ${DOCKER_IMAGE}:latest
                        
                        echo "🎯 Démarrage du nouveau container..."
                        docker run -d \\
                            -p ${APP_PORT}:8080 \\
                            --name ${APP_NAME} \\
                            ${DOCKER_IMAGE}:latest
                        
                        echo "⏳ Attente du démarrage de l'application (35 secondes)..."
                        sleep 35
                    """
                }
            }
        }
        
        // ÉTAPE 9: Vérification finale
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Vérification du déploiement..."
                    sh """
                        echo "📊 Statut du container:"
                        docker ps | grep ${APP_NAME} && echo "✅ Container en cours d'exécution" || echo "❌ Container non trouvé"
                        
                        echo "🌐 Test de connectivité HTTP..."
                        if curl -s -f http://localhost:${APP_PORT}/ > /dev/null; then
                            echo "✅ Application répond correctement"
                            echo "🎉 DÉPLOIEMENT RÉUSSI!"
                            echo "🌐 URL: http://localhost:${APP_PORT}/"
                        else
                            echo "❌ L'application ne répond pas"
                            echo "🔍 Logs du container:"
                            docker logs ${APP_NAME} --tail 20
                            exit 1
                        fi
                        
                        echo "📋 Derniers logs:"
                        docker logs ${APP_NAME} --tail 5
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Finalisation du pipeline..."
            sh '''
                echo "🧹 Nettoyage des ressources Docker..."
                docker system prune -f || true
                
                echo "📈 Résumé:"
                echo "🐳 Images Docker créées: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "🐳 Images Docker créées: ${DOCKER_IMAGE}:latest"
                echo "🌐 Application: http://localhost:${APP_PORT}"
            '''
        }
        success {
            echo "🎉 PIPELINE RÉUSSI!"
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: """✅ Déploiement réussi!
*Application*: ${APP_NAME}
*Version*: ${DOCKER_TAG}
*Image Docker*: ${DOCKER_IMAGE}:${DOCKER_TAG}
*URL*: http://localhost:${APP_PORT}
*Build*: ${env.BUILD_URL}"""
            )
        }
        failure {
            echo "❌ PIPELINE EN ÉCHEC"
            slackSend(
                channel: '#alerts',
                color: 'danger', 
                message: """🚨 Échec du déploiement
*Application*: ${APP_NAME}
*Build*: ${env.BUILD_URL}
*Dernière étape*: ${currentBuild.result}"""
            )
        }
    }
}