library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
   remote: 'https://gitlab.com/jokerwrld999/jenkins-shared-library.git'])

def gv

pipeline {
    agent any
    environment {
        repositoryName = 'jokerwrld'
        appName = 'java-maven-app'

        imageName = "$repositoryName/$appName"
    }
    stages {

        stage ("init") {
            steps {
                script {
                    gv = load 'stages.groovy'
                }
            }
        }
        stage ("increment version") {
            steps {
                script {
                    incrementVersion()
                }
            }
        }
        stage ("build app") {
            steps {
                script {
                    buildApp()
                }
            }
        }
        stage ("build image") {
            steps {
                script {
                    buildImage "$imageName:${versionTag}"
                    dockerLogin
                    pushImage "$imageName:${versionTag}"
                }
            }
        }
        stage ("deploy app") {
            steps {
                script {
                    gv.deployApp()
                }
            }
        }
        stage ("update version") {
            steps {
                script {
                    versionUpdate
                }
            }
        }
    }
}
