def registry = 'https://index.docker.io/v1/'
def imageName = 'srinualajangi/sample_app'
def version   = "2.1.2-${env.BUILD_NUMBER}"

pipeline {
    agent any
    tools {
        maven 'Maven 3.5.4' // Use the name you provided in the Global Tool Configuration
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
                sh 'ls -l target' // List the contents of the target directory
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
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.host.url=http://ec2-3-91-172-213.compute-1.amazonaws.com:9000/ -Dsonar.login=$SONAR_TOKEN"
                    }
                    echo "----------- SonarQube analysis completed ----------"
                }
            }
        }
        stage("Quality Gate") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        timeout(time: 1, unit: 'HOURS') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                error "Pipeline aborted due to quality gate failure: ${qg.status}"
                            }
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
                        nexusUrl: 'ec2-3-91-172-213.compute-1.amazonaws.com:8081',
                        groupId: 'com.example',
                        version: version,
                        repository: 'maven-releases',
                        credentialsId: 'nexus-cred',
                        artifacts: [
                            [artifactId: 'demo-workshop', classifier: '', file: 'target/demo-workshop-2.1.2.jar', type: 'jar']
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
                    app = docker.build(imageName + ":" + version, ".")
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
                    echo '<--------------- Deploy Started --------------->'
                    // Add your deployment steps here
                    echo '<--------------- Deploy Ended --------------->'
                }
            }
        }
    }
}
