def registry = 'https://index.docker.io/v1/'
def imageName = 'srinualajangi/sample_app'
def version   = '2.1.2'

pipeline {
    agent any
    tools {
        maven 'Maven 3.5.4' // Use the name you provided in the Global Tool Configuration
        sonarQube 'SonarQube' // Ensure this matches the name in Global Tool Configuration
    }
    environment {
        PATH = "/opt/apache-maven-3.5.4/bin:$PATH"
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
                scannerHome = tool name: 'SonarQube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    echo "----------- SonarQube analysis started ----------"
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.host.url=http://ec2-18-232-168-152.compute-1.amazonaws.com:9000/"
                    echo "----------- SonarQube analysis completed ----------"
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
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: 'ec2-18-232-168-152.compute-1.amazonaws.com:8081',
                        groupId: 'com.example',
                        version: version,
                        repository: 'maven-releases',
                        credentialsId: 'nexus-cred',
                        artifacts: [
                            [artifactId: 'sample_app', classifier: '', file: 'target/sample_app.jar', type: 'jar']
                        ]
                    )
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
                }
            }
        }
    }
}
