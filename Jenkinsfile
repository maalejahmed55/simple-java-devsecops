pipeline {
    agent any
    
    environment {
        SONAR_PROJECT_KEY = "simple-java-devsecops"
        SONAR_PROJECT_NAME = "Simple Java DevSecOps"
    }
    
    stages {
        stage('Diagnostic Complet') {
            steps {
                script {
                    echo "🔍 DIAGNOSTIC SONARQUBE COMPLET"
                    
                    // 1. Test connexion basique
                    sh '''
                        echo "1. Test connexion SonarQube..."
                        curl -v http://192.168.10.10:9000/api/system/status
                    '''
                    
                    // 2. Test credentials Jenkins
                    echo "2. Test credentials Jenkins..."
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            echo "Token length: ${#SONAR_TOKEN}"
                            echo "3. Test authentification avec token..."
                            curl -u "${SONAR_TOKEN}:" http://192.168.10.10:9000/api/system/status
                            
                            echo "4. Test création projet..."
                            curl -u "${SONAR_TOKEN}:" -X POST "http://192.168.10.10:9000/api/projects/create" \
                              -d "project=${SONAR_PROJECT_KEY}&name=${SONAR_PROJECT_NAME}" || echo "Création échouée"
                        '''
                    }
                    
                    // 3. Test manuel Maven
                    sh '''
                        echo "5. Test Maven manuel..."
                        mvn sonar:sonar \
                        -Dsonar.projectKey=simple-java-devsecops \
                        -Dsonar.sources=src \
                        -Dsonar.host.url=http://192.168.10.10:9000 \
                        -Dsonar.token=sqp_b0cf47f5c6a30692f381bbd3c0271121255e951d || echo "Maven échoué"
                    '''
                }
            }
        }
    }
}