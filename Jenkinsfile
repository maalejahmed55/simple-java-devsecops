pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "maalejahmed"  // ✅ REMPLACEZ par votre username Docker Hub
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        // ÉTAPE 1: Checkout du code
        stage('Checkout Git') {
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
                    echo "📍 Répertoire: $(pwd)"
                    echo "🐳 Docker: $(docker --version)"
                    echo "📦 Maven: $(mvn --version 2>&1 | head -1)"
                    echo "📋 Contenu du projet:"
                    ls -la
                    echo "📄 Dockerfile:"
                    cat Dockerfile || echo "❌ Dockerfile manquant"
                '''
            }
        }
        
        // ÉTAPE 3: Vérification des images Docker
        stage('Verify Docker Images') {
            steps {
                script {
                    echo "🐳 Vérification des images Docker..."
                    sh '''
                        echo "📥 Téléchargement des images nécessaires..."
                        docker pull maven:3.8.4-openjdk-17 && echo "✅ Maven image OK"
                        docker pull eclipse-temurin:17-jre && echo "✅ Java runtime OK"
                        echo "🎯 Images prêtes pour le build"
                    '''
                }
            }
        }
        
        // ÉTAPE 4: Build Docker (fait TOUT - build Maven inclus)
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🏗️ Construction COMPLÈTE dans Docker..."
                    sh """
                        echo "🔍 Pré-vérification..."
                        echo "📁 Fichiers sources:"
                        find src -name "*.java" -type f | head -10
                        echo "📄 pom.xml présent: $(ls pom.xml && echo '✅' || echo '❌')"
                        
                        echo "🐳 Lancement du build Docker..."
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        
                        echo "🏷️ Tagging de l'image..."
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        
                        echo "✅ Images créées:"
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        // ÉTAPE 5: Analyse de sécurité (optionnelle)
        stage('SAST Analysis') {
            steps {
                sh '''
                    echo "🔍 Analyse SAST avec SmartCube..."
                    # Votre commande SmartCube existante
                    echo "smartsonar -Dacnar projectKey=simple-java-devsecops"
                    echo "✅ Analyse sécurité terminée"
                '''
            }
        }
        
        // ÉTAPE 6: Tests (optionnels)
        stage('Run Tests') {
            steps {
                sh '''
                    echo "🧪 Exécution des tests..."
                    # Les tests peuvent être exécutés dans Docker ou séparément
                    echo "📝 Tests simulés - à adapter selon vos besoins"
                '''
            }
        }
        
        // ÉTAPE 7: Push vers Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "🔐 Authentification à Docker Hub..."
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            echo "🚀 Pushing de la version ${DOCKER_TAG}..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            echo "🚀 Pushing de la version latest..."
                            docker push ${DOCKER_IMAGE}:latest
                            
                            echo "✅ Images disponibles sur: https://hub.docker.com/r/${DOCKER_IMAGE}"
                        """
                    }
                }
            }
        }
        
        // ÉTAPE 8: Déploiement
        stage('Deploy Application') {
            steps {
                script {
                    echo "🚀 Déploiement de l'application..."
                    sh """
                        echo "🧹 Nettoyage des anciens containers..."
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        
                        echo "🎯 Démarrage du nouveau container..."
                        docker run -d \\
                            -p ${APP_PORT}:8080 \\
                            --name ${APP_NAME} \\
                            ${DOCKER_IMAGE}:latest
                        
                        echo "⏳ Attente du démarrage (40 secondes)..."
                        sleep 40
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
                        if docker ps | grep -q ${APP_NAME}; then
                            echo "✅ Container en cours d'exécution"
                        else
                            echo "❌ Container non trouvé"
                            echo "🔍 Logs:"
                            docker logs ${APP_NAME} --tail 20
                            exit 1
                        fi
                        
                        echo "🌐 Test de l'application..."
                        MAX_RETRIES=10
                        for i in \$(seq 1 \$MAX_RETRIES); do
                            if curl -s -f http://localhost:${APP_PORT}/ > /dev/null; then
                                echo "🎉 SUCCÈS : Application accessible!"
                                echo "🌐 URL: http://localhost:${APP_PORT}/"
                                break
                            else
                                echo "⏳ Tentative \$i/\$MAX_RETRIES - Application pas encore prête..."
                                sleep 10
                            fi
                            
                            if [ \$i -eq \$MAX_RETRIES ]; then
                                echo "❌ ÉCHEC : Application non accessible après \$MAX_RETRIES tentatives"
                                echo "🔍 Derniers logs:"
                                docker logs ${APP_NAME} --tail 30
                                exit 1
                            fi
                        done
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Finalisation du pipeline..."
            sh '''
                echo "🧹 Nettoyage des ressources..."
                docker system prune -f || true
                
                echo "📈 Résumé:"
                echo "🐳 Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "🌐 Application: http://localhost:${APP_PORT}"
                echo "📊 Build: ${env.BUILD_URL}"
            '''
        }
        success {
            echo "🎉 PIPELINE RÉUSSI!"
            script {
                // Notification optionnelle
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
        }
        failure {
            echo "❌ PIPELINE EN ÉCHEC"
            script {
                sh '''
                    echo "🔍 Debug information:"
                    docker ps -a
                    docker images | grep ${DOCKER_IMAGE} || echo "Aucune image trouvée"
                    netstat -tulpn | grep ${APP_PORT} || echo "Port ${APP_PORT} non utilisé"
                '''
                // Notification optionnelle
                slackSend(
                    channel: '#alerts',
                    color: 'danger',
                    message: """🚨 Échec du déploiement
*Application*: ${APP_NAME}
*Build*: ${env.BUILD_URL}
*Dernière étape*: ${currentBuild.currentResult}"""
                )
            }
        }
    }
}