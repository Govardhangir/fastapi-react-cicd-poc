pipeline {
    agent any

    environment {
        SONAR_HOST_URL    = "http://localhost:9000"
        SONAR_PROJECT_KEY = "fastapi-react-cicd-poc"

        // Used only for PR comment API
        GITHUB_OWNER = "Govardhangir"
        GITHUB_REPO  = "fastapi-react-cicd-poc"
    }

    stages {

        stage('Checkout Code') {
            steps {
                // REQUIRED for Multibranch Pipeline
                checkout scm
            }
        }

        stage('Backend – Static Validation') {
            steps {
                dir('backend') {
                    sh 'python3 -m compileall app'
                }
            }
        }

        stage('Frontend – Build') {
            steps {
                dir('frontend') {
                    sh '''
                        set -e
                        npm ci
                        npm run build
                    '''
                }
            }
        }

        stage('Frontend – Lint') {
            steps {
                dir('frontend') {
                    sh '''
                        set -e
                        if npm run | grep -q lint; then
                          npm run lint
                        else
                          echo "Lint not configured - skipping"
                        fi
                    '''
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([
                        string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')
                    ]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                              -Dsonar.projectName="FastAPI React CI/CD PoC" \
                              -Dsonar.sources=backend/app,frontend/src \
                              -Dsonar.exclusions=**/node_modules/**,**/venv/**,**/test-venv/** \
                              -Dsonar.sourceEncoding=UTF-8 \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.token=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Security Scan – Trivy') {
            steps {
                sh '''
                    trivy fs \
                      --exit-code 1 \
                      --severity CRITICAL \
                      --no-progress \
                      .
                '''
            }
        }

        stage('Archive Build Artifacts') {
            steps {
                archiveArtifacts artifacts: 'frontend/dist/**', fingerprint: true
            }
        }
    }

    post {

        always {
            script {
                // This is TRUE only for PR builds in Multibranch
                if (env.CHANGE_ID) {

                    withCredentials([
                        string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN'),
                        string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')
                    ]) {

                        // Fetch Sonar metrics
                        def metrics = sh(
                            script: """
                              curl -s -u ${SONAR_TOKEN}: \
                              "${SONAR_HOST_URL}/api/measures/component?component=${SONAR_PROJECT_KEY}&metricKeys=bugs,vulnerabilities,code_smells,coverage,alert_status"
                            """,
                            returnStdout: true
                        ).trim()

                        def bugs     = metrics =~ /"metric":"bugs","value":"(.*?)"/ ? (metrics =~ /"metric":"bugs","value":"(.*?)"/)[0][1] : "0"
                        def vulns    = metrics =~ /"metric":"vulnerabilities","value":"(.*?)"/ ? (metrics =~ /"metric":"vulnerabilities","value":"(.*?)"/)[0][1] : "0"
                        def smells   = metrics =~ /"metric":"code_smells","value":"(.*?)"/ ? (metrics =~ /"metric":"code_smells","value":"(.*?)"/)[0][1] : "0"
                        def coverage = metrics =~ /"metric":"coverage","value":"(.*?)"/ ? (metrics =~ /"metric":"coverage","value":"(.*?)"/)[0][1] : "0"
                        def gate     = metrics =~ /"metric":"alert_status","value":"(.*?)"/ ? (metrics =~ /"metric":"alert_status","value":"(.*?)"/)[0][1] : "UNKNOWN"

                        def gateIcon = gate == "OK" ? "✅ PASSED" : "❌ FAILED"

                        def comment = """
### 🔍 SonarQube Analysis Summary

**Quality Gate:** ${gateIcon}

| Metric | Value |
|------|------|
| 🐞 Bugs | ${bugs} |
| 🔐 Vulnerabilities | ${vulns} |
| 🧹 Code Smells | ${smells} |
| 📊 Coverage | ${coverage}% |

🔗 **Build:** ${BUILD_URL}

> Enforced by Jenkins using **SonarQube Community Edition**
"""

                        sh """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Accept: application/vnd.github.v3+json" \
                          https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/issues/${env.CHANGE_ID}/comments \
                          -d '{ "body": "${comment.replaceAll('"', '\\\\\"')}" }'
                        """
                    }
                }
            }
        }
    }
}
