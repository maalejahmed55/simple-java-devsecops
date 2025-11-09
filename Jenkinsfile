pipeline {
    agent any
    
    environment {
        APP_NAME = "simple-java-devsecops"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar-server') {
                        sh '''
                            echo "🔍 Analyse SAST avec SonarQube..."
                            mvn sonar:sonar \
                              -Dsonar.projectKey=simple-java-devsecops \
                              -Dsonar.projectName="Simple Java DevSecOps" \
                              -Dsonar.host.url=http://localhost:9000
                        '''
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'echo "Tests unitaires..."'
            }
        }
    }
    
    post {
        always {
            echo "🏁 Pipeline terminé"
        }
    }
}