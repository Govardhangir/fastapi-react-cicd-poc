pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                echo "Checking out code from GitHub (develop branch)"
                git branch: 'develop',
                    url: 'https://github.com/Govardhangir/fastapi-react-cicd-poc.git'
            }
        }

        stage('Build Backend (FastAPI)') {
            steps {
                dir('backend') {
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt || pip install .
                        python -c "from app.main import app; print('FastAPI app loaded successfully')"
                    '''
                }
            }
        }

        stage('Build Frontend (React)') {
            steps {
                dir('frontend') {
                    sh '''
                        npm install
                        npm run build
                    '''
                }
            }
        }
    }
}
