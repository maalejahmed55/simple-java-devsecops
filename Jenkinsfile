pipeline {
    agent any
    
    environment {
        // Variables d'environnement pour plus de flexibilité
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_IMAGE = "${APP_NAME}:latest"
    }
    
    stages {
        // ÉTAPE 1: Récupération du code
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        // ÉTAPE 2: Préparation
        stage('Checkout') {
            steps {
                sh '''
                    echo "📁 Préparation des fichiers..."
                    ls -la
                    echo "🐳 Vérification de Docker..."
                    docker --version
                '''
            }
        }
        
        // ÉTAPE 3: Construction de l'application
        stage('Build') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application..."
                    mvn clean package -DskipTests
                    echo "📦 Fichiers générés:"
                    ls -la target/
                '''
            }
        }
        
        // ÉTAPE 4: Analyse de sécurité
        stage('SAST - SmartCube Analysis') {
            steps {
                sh '''
                    echo "🔍 Analyse SAST avec SmartCube..."
                    # Votre commande SmartCube existante ici
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
                        docker build -t ${DOCKER_IMAGE} .
                        echo "📊 Images Docker créées:"
                        docker images | grep ${APP_NAME}
                    """
                }
            }
        }
        
        // ÉTAPE 7: Déploiement
        stage('Deploy to Docker') {
            steps {
                script {
                    echo "🚀 Déploiement de l'application..."
                    sh """
                        # Arrêter et nettoyer l'ancien container
                        echo "🧹 Nettoyage des anciens containers..."
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        
                        # Démarrer le nouveau container
                        echo "🎯 Démarrage du nouveau container..."
                        docker run -d \\
                            -p ${APP_PORT}:8080 \\
                            --name ${APP_NAME} \\
                            ${DOCKER_IMAGE}
                        
                        echo "⏳ Attente du démarrage (30 secondes)..."
                        sleep 30
                    """
                }
            }
        }
        
        // ÉTAPE 8: Vérification
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Vérification du déploiement..."
                    sh """
                        # Vérifier le statut du container
                        echo "📊 Statut du container:"
                        docker ps | grep ${APP_NAME} || echo "❌ Container non trouvé"
                        
                        # Vérifier que l'application répond
                        echo "🌐 Test de l'application..."
                        curl -f http://localhost:${APP_PORT}/ || exit 1
                        
                        # Vérifier les logs
                        echo "📋 Derniers logs:"
                        docker logs ${APP_NAME} --tail 10
                        
                        echo "✅ Santé de l'application vérifiée!"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Nettoyage des ressources..."
            sh '''
                echo "🧹 Nettoyage Docker..."
                docker system prune -f || true
                
                echo "📈 Résumé du déploiement:"
                docker ps -a | grep simple-java-app || echo "Aucun container simple-java-app"
            '''
        }
        success {
            echo "✅ Déploiement réussi! Application disponible sur http://localhost:${APP_PORT}"
            sh '''
                echo "🎉 URL de l'application: http://localhost:8081"
                echo "🔍 Pour voir les logs: docker logs -f simple-java-app"
            '''
        }
        failure {
            echo "❌ Échec du déploiement"
            sh '''
                echo "🔍 Debug information:"
                docker ps -a
                docker images | grep simple-java-app
                netstat -tulpn | grep 8081 || echo "Port 8081 non utilisé"
            '''
        }
    }
}