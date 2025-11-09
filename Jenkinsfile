pipeline {
    agent any
    
    stages {
        stage('Test Connection') {
            steps {
                echo "🎉 CONNECTION TEST - Démarrage du pipeline"
                sh 'pwd'
                sh 'ls -la'
                sh 'echo "Java version:" && java -version'
                sh 'echo "Maven version:" && mvn --version || echo "Maven non installé"'
            }
        }
    }
    
    post {
        always {
            echo "✅ Test terminé - Build ${env.BUILD_NUMBER}"
        }
    }
}