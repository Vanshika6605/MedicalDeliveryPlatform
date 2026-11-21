pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'node --version && npm ci --no-audit --no-fund && npm --prefix backend ci --no-audit --no-fund'
                    } else {
                        bat 'node --version && call npm.cmd ci --no-audit --no-fund && call npm.cmd --prefix backend ci --no-audit --no-fund'
                    }
                }
            }
        }
        stage('Run Tests') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'npm test'
                    } else {
                        bat 'npm.cmd test'
                    }
                }
            }
        }
        stage('Build Application') {
            environment {
                VITE_API_URL = '/api'
            }
            steps {
                script {
                    if (isUnix()) {
                        sh 'npm run build'
                    } else {
                        bat 'npm.cmd run build'
                    }
                }
                archiveArtifacts artifacts: 'dist/**', fingerprint: true
            }
        }
    }

    post {
        success {
            echo 'MediFlow tests passed and the production frontend was archived.'
        }
        failure {
            echo 'See Console Output for the failing stage.'
        }
    }
}
