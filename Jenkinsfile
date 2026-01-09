pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    environment {
        SONAR_HOST_URL    = 'http://localhost:9000'
        SONAR_PROJECT_KEY = 'fastapi-react-cicd-poc'
    }

    stages {

        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Detect Build Context') {
            steps {
                script {
                    if (env.CHANGE_ID) {
                        echo "PR Build #${env.CHANGE_ID} → Target: ${env.CHANGE_TARGET}"
                    } else {
                        echo "Branch Build → ${env.BRANCH_NAME}"
                    }
                }
            }
        }

        stage('Backend – Syntax Check') {
            steps {
                dir('backend') {
                    sh 'python3 -m compileall app'
                }
            }
        }

        stage('Frontend – Install & Build') {
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
                          echo "Lint not configured – skipping"
                        fi
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([
                        string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')
                    ]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                              -Dsonar.projectName="FastAPI React CI/CD PoC" \
                              -Dsonar.sources=backend/app,frontend/src \
                              -Dsonar.exclusions=**/node_modules/**,**/venv/** \
                              -Dsonar.sourceEncoding=UTF-8 \
                              -Dsonar.host.url=${SONAR_HOST_URL} \
                              -Dsonar.token=${SONAR_TOKEN}
                        '''
                    }
                }
            }
        }

        stage('Quality Gate (BLOCKER)') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Security Scan – Trivy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    expression { env.CHANGE_ID != null }
                }
            }
            steps {
                sh '''
                    trivy fs \
                      --severity CRITICAL \
                      --exit-code 1 \
                      --no-progress \
                      .
                '''
            }
        }

        stage('Archive Artifacts') {
            when {
                branch 'main'
            }
            steps {
                archiveArtifacts artifacts: 'frontend/dist/**', fingerprint: true
            }
        }
    }

    post {

        success {
            emailext(
                subject: "✅ CI PASSED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                to: 'govardhangiri.m@gmail.com',
                mimeType: 'text/html',
                body: """
                    <h3>CI Status: SUCCESS</h3>
                    <p><b>Branch:</b> ${env.BRANCH_NAME}</p>
                    <p><b>Build:</b> #${env.BUILD_NUMBER}</p>
                    <p><b>Quality Gate:</b> PASSED</p>
                    <p><a href="${env.BUILD_URL}">View Build</a></p>
                """
            )
        }

        failure {
            emailext(
                subject: "❌ CI FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                to: 'govardhangiri.m@gmail.com',
                mimeType: 'text/html',
                body: """
                    <h3>CI Status: FAILED</h3>
                    <p><b>Branch:</b> ${env.BRANCH_NAME}</p>
                    <p><b>Reason:</b> Quality Gate or Security Failure</p>
                    <p><a href="${env.BUILD_URL}">View Build</a></p>
                """
            )
        }
    }
}

