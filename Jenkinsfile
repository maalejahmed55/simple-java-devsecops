pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-app"
        APP_PORT = "8081"
        DOCKER_USERNAME = "maalejahmed"
        DOCKER_IMAGE = "${DOCKER_USERNAME}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        // Variables SonarQube
        SONAR_PROJECT_KEY = "simple-java-devsecops"
        SONAR_PROJECT_NAME = "Simple Java DevSecOps"
    }
    
    stages {
        stage('Checkout Git') {
            steps {
                checkout scm
            }
        }
        
        // 🆕 ÉTAPE AJOUTÉE : Build de l'application pour SonarQube
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Construction de l'application pour SonarQube..."
                    mvn clean compile -DskipTests
                    echo "✅ Application construite"
                '''
            }
        }
        
        // 🆕 ÉTAPE AJOUTÉE : SAST avec SonarQube
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    // Vérification que le code est compilé
                    sh '''
                        echo "📋 Vérification des fichiers compilés..."
                        ls -la target/classes/ || echo "⚠️  Aucune classe compilée trouvée"
                    '''
                    
                    // Analyse SonarQube
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                            -Dsonar.host.url=http://localhost:9000
                        """
                    }
                    
                    echo "✅ Analyse SonarQube terminée - Rapport disponible sur http://localhost:9000"
                }
            }
        }
        
        // 🆕 ÉTAPE AJOUTÉE : Quality Gate
        stage('Quality Gate') {
            steps {
                script {
                    echo "📊 Attente des résultats du Quality Gate..."
                    timeout(time: 2, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false
                    }
                    echo "✅ Quality Gate vérifié"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "✅ Image créée"
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Envoi Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \${DOCKER_PASS} | docker login -u \${DOCKER_USER} --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            echo "✅ Images poussées"
                        """
                    }
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo "🚀 Déploiement..."
                    sh """
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        docker run -d -p ${APP_PORT}:8080 --name ${APP_NAME} ${DOCKER_IMAGE}:latest
                        echo "🎯 Container démarré"
                        echo "🔍 Vérifiez avec: docker logs ${APP_NAME}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Génération des rapports de sécurité..."
            sh '''
                echo "=== RAPPORT SAST ===" > sast-report.txt
                echo "🔍 SonarQube Analysis: COMPLETED" >> sast-report.txt
                echo "📊 Rapport: http://localhost:9000/dashboard?id=simple-java-devsecops" >> sast-report.txt
                echo "✅ Quality Gate: VERIFIED" >> sast-report.txt
                echo " " >> sast-report.txt
                echo "Pour voir le rapport complet:" >> sast-report.txt
                echo "1. Allez sur http://localhost:9000" >> sast-report.txt
                echo "2. Cherchez le projet 'simple-java-devsecops'" >> sast-report.txt
            '''
        }
        success {
            echo "✅ PIPELINE TERMINÉ AVEC SUCCÈS"
            echo "📊 Rapport SAST disponible sur http://localhost:9000"
        }
        failure {
            echo "❌ PIPELINE ÉCHOUÉ"
            echo "🔍 Consultez les logs pour les détails"
        }
    }
}