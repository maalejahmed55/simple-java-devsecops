stage('SAST - SonarQube Analysis') {
    steps {
        script {
            echo "🔍 SAST: Création et analyse projet..."
            
            withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                sh """
                    // Création explicite du projet
                    curl -u "${SONAR_TOKEN}:" -X POST "http://192.168.10.10:9000/api/projects/create" \
                      -d "project=${SONAR_PROJECT_KEY}&name=${SONAR_PROJECT_NAME}" || echo "Projet existe peut-être déjà"
                    
                    // Analyse
                    mvn sonar:sonar \
                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                    -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                    -Dsonar.sources=src \
                    -Dsonar.java.binaries=target/classes \
                    -Dsonar.host.url=http://192.168.10.10:9000 \
                    -Dsonar.token=${SONAR_TOKEN}
                """
            }
        }
    }
}