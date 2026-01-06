pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                echo "Checking out code from GitHub (develop branch)"
                git branch: 'develop',
                    url: 'https://github.com/Govardhangir/fastapi-react-cicd-poc.git/'
            }
        }
    }
}
