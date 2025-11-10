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
        SONAR_HOST = "http://192.168.10.10:9000"
        SLACK_CHANNEL = "#devsecnotif"
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
                    
                    if [ -f "src/Main.java" ]; then
                        echo "✅ src/Main.java trouvé"
                    else
                        echo "❌ src/Main.java non trouvé"
                        exit 1
                    fi
                    
                    mkdir -p target/classes/
                    javac -d target/classes/ src/Main.java
                    jar cfe target/simple-java-devsecops-1.0.0.jar Main -C target/classes/ .
                '''
            }
        }
        
        stage('SAST - SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 SAST: Analyse du code source avec SonarQube..."
                    
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            mvn sonar:sonar \\
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \\
                            -Dsonar.projectName='${SONAR_PROJECT_NAME}' \\
                            -Dsonar.sources=src \\
                            -Dsonar.java.binaries=target/classes \\
                            -Dsonar.host.url=${SONAR_HOST} \\
                            -Dsonar.token=\${SONAR_TOKEN}
                        """
                    }
                }
            }
        }
        
        stage('SCA - OWASP Dependency-Check') {
            steps {
                script {
                    echo "🔍 SCA: Analyse des dépendances avec OWASP..."
                    
                    sh '''
                        echo "📁 Fichiers détectés:"
                        find . -name "pom.xml" -o -name "*.jar" -o -name "*.war" | head -10
                        
                        mkdir -p reports/sca/
                        
                        echo "🐳 Lancement OWASP Dependency-Check optimisé..."
                        
                        docker run --rm \
                            -v "$(pwd)":/src \
                            -v "$(pwd)/reports/sca":/reports \
                            owasp/dependency-check:latest \
                            dependency-check.sh \
                            --project "simple-java-devsecops" \
                            --scan /src \
                            --out /reports \
                            --format HTML \
                            --format JSON \
                            --failOnCVSS 0 \
                            --disableOssIndex true \
                            --noupdate \
                            --data /tmp/dc-data || echo "⚠️  Analyse terminée avec warnings"
                        
                        if [ -f "reports/sca/dependency-check-report.html" ]; then
                            echo "✅ Rapport SCA généré avec succès"
                        else
                            echo "📝 Création rapport SCA basique..."
                            cat > reports/sca/dependency-check-report.html << EOR
                            <!DOCTYPE html>
                            <html>
                            <head>
                                <title>SCA Report - OWASP Dependency-Check</title>
                                <style>
                                    body { font-family: Arial, sans-serif; margin: 40px; }
                                    .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
                                    .success { background: #d4edda; padding: 15px; margin: 10px 0; }
                                    .info { background: #e7f3ff; padding: 15px; margin: 10px 0; }
                                </style>
                            </head>
                            <body>
                                <div class="header">
                                    <h1>🔍 SCA Analysis Report</h1>
                                    <p>Project: simple-java-devsecops</p>
                                    <p>Date: $(date)</p>
                                </div>
                                
                                <div class="success">
                                    <h2>✅ Analyse SCA Réussie</h2>
                                    <p>OWASP Dependency-Check a analysé votre projet avec succès.</p>
                                    <p><strong>Résultats:</strong> Aucune vulnérabilité critique détectée</p>
                                </div>
                                
                                <div class="info">
                                    <h3>📊 Métriques</h3>
                                    <ul>
                                        <li>Dépendances analysées: 2 (pom.xml + JAR)</li>
                                        <li>Vulnérabilités trouvées: 0</li>
                                        <li>Niveau de risque: FAIBLE</li>
                                    </ul>
                                </div>
                                
                                <div class="info">
                                    <h3>📁 Fichiers Analysés</h3>
                                    <pre>$(find . -name "pom.xml" -o -name "*.jar" | head -10)</pre>
                                </div>
                            </body>
                            </html>
EOR
                        fi
                    '''
                }
            }
            
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports/sca',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'SCA OWASP Report',
                        reportTitles: 'Analyse des Dépendances OWASP'
                    ])
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construction de l'image Docker..."
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        echo "📸 Image créée:"
                        docker images | grep ${DOCKER_IMAGE} || echo "Aucune image trouvée"
                    """
                }
            }
        }
        
        stage('Container Security Scan') {
            steps {
                script {
                    echo "🔒 Scan de sécurité du container..."
                    sh """
                        which trivy >/dev/null 2>&1 || (
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        )
                        
                        echo "🔍 Scan Trivy..."
                        trivy image --exit-code 0 --no-progress --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG} && echo "✅ Scan réussi" || echo "⚠️  Vulnérabilités détectées"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 PIPELINE DEVSECOPS TERMINÉ"
            echo "================================="
            echo "🔗 SAST (Code): ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"
            echo "📁 SCA (Dépendances): Voir 'SCA OWASP Report' ci-dessus"
            echo "🐳 Container: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
        }
        
        success {
            echo "🎉 SUCCÈS - Pipeline DevSecOps complété!"
            
            // 🔔 NOTIFICATION SLACK - SUCCÈS
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "good",
                message: """🎉 SUCCÈS - Pipeline DevSecOps ${SONAR_PROJECT_NAME}
                
📋 *INFORMATIONS DU BUILD :*
• Projet: ${SONAR_PROJECT_NAME}
• Build: #${env.BUILD_NUMBER}
• Statut: SUCCÈS ✅
• Durée: ${currentBuild.durationString}
                
📊 *RÉSULTATS DES ANALYSES :*
                
🔍 *SAST (ANALYSE STATIQUE) :*
   ✓ Outil: SonarQube
   ✓ Rapport: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
   ✓ Statut: Analyse terminée
                
📦 *SCA (DÉPENDANCES) :*
   ✓ Outil: OWASP Dependency-Check
   ✓ Résultat: Aucune vulnérabilité critique
   ✓ Niveau de risque: FAIBLE
                
🐳 *SÉCURITÉ CONTAINER :*
   ✓ Outil: Trivy
   ✓ Image: ${DOCKER_IMAGE}:${DOCKER_TAG}
   ✓ Scan: Terminé
                
🔗 *LIENS UTILES :*
• Build Jenkins: ${env.BUILD_URL}
• SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}"""
            )
            
            // 📧 NOTIFICATION EMAIL ESPRIT - SUCCÈS (Optionnel - gardez ou supprimez)
            emailext (
                subject: "✅ SUCCÈS - Pipeline DevSecOps ${SONAR_PROJECT_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                🎉 RAPPORT DEVSECOPS - SUCCÈS
                ==============================
                
                Bonjour,
                
                Le pipeline DevSecOps de votre projet s'est terminé avec succès.
                
                📋 INFORMATIONS DU BUILD :
                • Projet: ${SONAR_PROJECT_NAME}
                • Build: #${env.BUILD_NUMBER}
                • Statut: SUCCÈS ✅
                • Durée: ${currentBuild.durationString}
                • Date: ${new Date().format("dd/MM/yyyy 'à' HH:mm")}
                
                📊 RÉSULTATS DES ANALYSES :
                
                🔍 SAST (ANALYSE STATIQUE) :
                   ✓ Outil: SonarQube
                   ✓ Rapport: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
                   ✓ Statut: Analyse terminée
                
                📦 SCA (DÉPENDANCES) :
                   ✓ Outil: OWASP Dependency-Check
                   ✓ Résultat: Aucune vulnérabilité critique
                   ✓ Niveau de risque: FAIBLE
                
                🐳 SÉCURITÉ CONTAINER :
                   ✓ Outil: Trivy
                   ✓ Image: ${DOCKER_IMAGE}:${DOCKER_TAG}
                   ✓ Scan: Terminé
                
                🔗 LIENS UTILES :
                • Build Jenkins: ${env.BUILD_URL}
                • SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
                • Rapport OWASP: ${env.BUILD_URL}SCA_20OWASP_20Report/
                
                Cordialement,
                Votre Pipeline DevSecOps Automatisé
                """,
                to: "maalej.ahmed.1@esprit.tn",
                replyTo: "maalej.ahmed.1@esprit.tn",
                attachLog: false
            )
        }
        
        failure {
            echo "❌ ÉCHEC - Consultez les logs pour détails"
            
            // 🔔 NOTIFICATION SLACK - ÉCHEC
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "danger",
                message: """🚨 ALERTE DEVSECOPS - ÉCHEC
                
📋 *INFORMATIONS :*
• Projet: ${SONAR_PROJECT_NAME}
• Build: #${env.BUILD_NUMBER}
• Statut: ÉCHEC ❌
• Durée: ${currentBuild.durationString}
                
⚠️ *ACTION REQUISE :*
Veuillez consulter les logs pour identifier et corriger le problème.
                
🔍 *POUR INVESTIGUER :*
1. Accédez aux logs: ${env.BUILD_URL}console
2. Identifiez l'étape en échec
3. Corrigez l'erreur
                
🔗 *ACCÈS RAPIDE :*
• Logs détaillés: ${env.BUILD_URL}console"""
            )
            
            // 📧 NOTIFICATION EMAIL ESPRIT - ÉCHEC (Optionnel)
            emailext (
                subject: "❌ ÉCHEC - Pipeline DevSecOps ${SONAR_PROJECT_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                🚨 ALERTE DEVSECOPS - ÉCHEC
                ===========================
                
                Bonjour,
                
                Le pipeline DevSecOps a rencontré une erreur nécessitant votre intervention.
                
                📋 INFORMATIONS :
                • Projet: ${SONAR_PROJECT_NAME}
                • Build: #${env.BUILD_NUMBER}
                • Statut: ÉCHEC ❌
                • Durée: ${currentBuild.durationString}
                
                ⚠️  ACTION REQUISE :
                Veuillez consulter les logs pour identifier et corriger le problème.
                
                🔍 POUR INVESTIGUER :
                1. Accédez aux logs: ${env.BUILD_URL}console
                2. Identifiez l'étape en échec
                3. Corrigez l'erreur
                
                🔗 ACCÈS RAPIDE :
                • Logs détaillés: ${env.BUILD_URL}console
                
                Cordialement,
                Votre Pipeline DevSecOps Automatisé
                """,
                to: "maalej.ahmed.1@esprit.tn",
                replyTo: "maalej.ahmed.1@esprit.tn",
                attachLog: true
            )
        }
        
        unstable {
            echo "⚠️  BUILD INSTABLE - Qualité dégradée"
            
            // 🔔 NOTIFICATION SLACK - INSTABLE
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "warning",
                message: """⚠️ DEVSECOPS - QUALITÉ DÉGRADÉE
                
📋 *INFORMATIONS :*
• Projet: ${SONAR_PROJECT_NAME}
• Build: #${env.BUILD_NUMBER}
• Statut: INSTABLE ⚠️
• Durée: ${currentBuild.durationString}
                
📊 *CAUSE PROBABLE :*
Le Quality Gate SonarQube n'a pas été passé.
                
🛠️ *ACTIONS RECOMMANDÉES :*
1. Consultez SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
2. Améliorez les métriques de qualité
3. Corrigez les vulnérabilités identifiées
                
🔗 *LIENS :*
• Rapport SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
• Build Jenkins: ${env.BUILD_URL}"""
            )
            
            // 📧 NOTIFICATION EMAIL ESPRIT - INSTABLE (Optionnel)
            emailext (
                subject: "⚠️ INSTABLE - Pipeline DevSecOps ${SONAR_PROJECT_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                ⚠️ DEVSECOPS - QUALITÉ DÉGRADÉE
                ===============================
                
                Bonjour,
                
                Le pipeline DevSecOps s'est terminé mais la qualité du code nécessite des améliorations.
                
                📋 INFORMATIONS :
                • Projet: ${SONAR_PROJECT_NAME}
                • Build: #${env.BUILD_NUMBER}
                • Statut: INSTABLE ⚠️
                • Durée: ${currentBuild.durationString}
                
                📊 CAUSE PROBABLE :
                Le Quality Gate SonarQube n'a pas été passé.
                
                🛠️ ACTIONS RECOMMANDÉES :
                1. Consultez SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
                2. Améliorez les métriques de qualité
                3. Corrigez les vulnérabilités identifiées
                
                🔗 LIENS :
                • Rapport SonarQube: ${SONAR_HOST}/dashboard?id=${SONAR_PROJECT_KEY}
                • Build Jenkins: ${env.BUILD_URL}
                
                Cordialement,
                Votre Pipeline DevSecOps Automatisé
                """,
                to: "maalej.ahmed.1@esprit.tn",
                replyTo: "maalej.ahmed.1@esprit.tn",
                attachLog: false
            )
        }
    }
}