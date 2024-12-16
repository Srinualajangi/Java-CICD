def registry = 'https://index.docker.io/v1/'
def imageName = 'srinualajangi/sample_app'
def version   = '2.1.2'

pipeline {
    agent any
    environment {
        PATH = "/opt/apache-maven-3.9.4/bin:$PATH"
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Srinualajangi/Java-CICD.git', branch: 'main', credentialsId: 'github-cred'
            }
        }
        stage("build") {
            steps {
                echo "----------- build started ----------"
                sh 'mvn clean deploy -Dmaven.test.skip=true'
                echo "----------- build completed ----------"
            }
        }
        stage("test") {
            steps {
                echo "----------- unit test started ----------"
                sh 'mvn surefire-report:report'
                echo "----------- unit test completed ----------"
            }
        }
        stage('SonarQube analysis') {
            environment {
                scannerHome = tool 'satish-sonarqube-scanner'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.host.url=http://ec2-18-232-168-152.compute-1.amazonaws.com:9000/"
                }
            }
        }
        stage("Quality Gate") {
            steps {
                script {
                    timeout(time: 1, unit: 'HOURS') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        stage("Nexus Publish") {
            steps {
                script {
                    echo '<--------------- Nexus Publish Started --------------->'
                    sh 'mvn deploy -DaltDeploymentRepository=nexus::default::http://ec2-18-232-168-152.compute-1.amazonaws.com:8081/repository/maven-releases/'
                    echo '<--------------- Nexus Publish Ended --------------->'
                }
            }
        }
        stage("Docker Build") {
            steps {
                script {
                    echo '<--------------- Docker Build Started --------------->'
                    app = docker.build(imageName + ":" + version)
                    echo '<--------------- Docker Build Ends --------------->'
                }
            }
        }
        stage("Docker Publish") {
            steps {
                script {
                    echo '<--------------- Docker Publish Started --------------->'
                    docker.withRegistry(registry, 'dockerhub-cred') {
                        app.push()
                    }
                    echo '<--------------- Docker Publish Ended --------------->'
                }
            }
        }
        stage("Deploy") {
            steps {
                script {
                    echo '<--------------- Helm Deploy Started --------------->'
                    sh 'helm install sample-app sample-app-1.0.1'
                    echo '<--------------- Helm Deploy Ends --------------->'
                }
            }
        }
    }
}
