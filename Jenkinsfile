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
                    find . -name "*.java" -type f | head -10
                    ls -la src/ || echo "❌ Dossier src/ manquant"
                    
                    # Compilation forcée
                    echo "🔨 Compilation Maven..."
                    mvn clean compile -DskipTests
                    
                    # Vérification
                    echo "📋 Vérification post-compilation:"
                    ls -la target/ || echo "❌ Dossier target/ manquant"
                    find target/ -name "*.class" | head -5 || echo "⚠️  Aucune classe compilée"
                    ls -la target/classes/ || echo "❌ Dossier classes/ manquant"
                    
                    # Packaging
                    mvn package -DskipTests
                    ls -la target/*.jar || echo "❌ Aucun JAR créé"
                    
                    echo "✅ Build terminé avec vérification"
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    // Vérification finale avant SonarQube
                    sh '''
                        echo "🎯 Préparation pour SonarQube..."
                        echo "📊 Fichiers disponibles:"
                        find target/classes/ -name "*.class" | wc -l || echo "0 classes"
                        ls -la target/*.jar || echo "Aucun JAR"
                    '''
                    
                    // Analyse SonarQube
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.host.url=http://localhost:9000
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
                    timeout(time: 2, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false
                    }
                    echo "✅ Quality Gate vérifié"
                }
            }
        }
        
        // ... [les autres étapes restent identiques]
    }
    
    post {
        always {
            echo "📊 Rapport de build..."
            sh '''
                echo "=== RAPPORT BUILD ===" > build-report.txt
                echo "Compilation: $(find target/ -name "*.class" | wc -l) classes" >> build-report.txt
                echo "JAR: $(ls target/*.jar 2>/dev/null | wc -l) fichiers" >> build-report.txt
                echo "SonarQube: http://localhost:9000" >> build-report.txt
            '''
        }
    }
}