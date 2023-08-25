/**
**/

library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
   remote: 'https://github.com/jokerwrld999/jenkins-shared-library.git'])

pipeline {
    agent any
    options {
        ansiColor('xterm')
    }
    parameters {
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Terraform Configuration Action')
    }
    environment {
        // Docker
        repositoryName = 'ghcr.io/jokerwrld999'
        appName = 'java-maven-app'
        dockerImage = "${env.repositoryName}/${env.appName}"

        // Config Tools
        githubDir = '~/github'
        repoName = '$(basename $repoSource | cut -d . -f 1)'
        localVCDir = "${githubDir}/${repoName}"
        repoCloneScript = 'https://raw.githubusercontent.com/jokerwrld999/java-maven-app/main/scripts/repo_clone.sh'
        repoCloneCmd = 'curl $repoCloneScript | bash -s $repoSource'

        // Terraform
        terraformRepo = 'https://github.com/jokerwrld999/terraform-ec2.git'

        // Ansible
        ansibleRepo = 'https://github.com/jokerwrld999/ansible-ec2.git'
        customUser = "webserver"
        catchError = "{ echo 'Error: Command failed with exit code \$?'; exit 1; }"


        // SSH
        remoteHost = "ansible@192.168.10.20"
        sshConnect = "ssh -o StrictHostKeyChecking=no ${remoteHost}"
    }
    stages {
        stage ("Build Image") {
            when {
                anyOf {
                    expression  {
                        currentBuild.number == 1
                    }
                    changeset "src/**"
                    changeset "Dockerfile"
                }
            }
            steps {
                incrementVersion()
                dockerLogin()
                dockerBuild("${env.dockerImage}:$versionTag")
                dockerPush("${env.dockerImage}:$versionTag")
                pushVersion()
            }
        }

        stage ("Provision Server") {
            // when {
            //     beforeAgent true
            //     expression {
            //         env.SKIP == "true"
            //     }
            // }
            environment {
                // Config Tools
                repoSource = "${env.terraformRepo}"
            }
            steps {
                echo "Deploying infrastructure..."

                sshagent(credentials: ['ansible-server-key']) {
                    sh(""" ${env.sshConnect} "
                        ${env.repoCloneCmd}
                        "
                    """)

                    sh(""" ${env.sshConnect} "
                        cd ${env.localVCDir}
                        [ -d .terraform ] || { terraform init && terraform plan }
                        terraform ${params.action} --auto-approve
                        "
                    """)
                }
            }
        }

        stage ("Setup Docker") {
            when {
                anyOf {
                    expression  {
                        "${params.action}" != "destroy"
                    }

                }
            }
            environment {
                // Config Tools
                repoSource = "${env.ansibleRepo}"

                // Ansible
                vaultPass = credentials('ansible_vault_pass')
            }
            steps {
                echo "Installing Docker..."

                sshagent(credentials: ['ansible-server-key']) {
                    sh(""" ${env.sshConnect} "
                        ${env.repoCloneCmd}
                        "
                    """)

                    sh(""" ${env.sshConnect} "
                        export CUSTOM_USER=${env.customUser}

                        cd ${env.localVCDir}
                        [ -s ${env.localVCDir}/.vault_pass ] || { echo $vaultPass > ${env.localVCDir}/.vault_pass }
                        ansible-galaxy collection install -r requirements.yml
                        { ansible -i inventory/inventory_aws_ec2.yaml aws_ec2 -m shell -a 'which docker' } || ansible-playbook local.yaml --tags docker || ${env.catchError}
                        "
                    """)
                }
            }
        }

        stage ("Deploy App") {
            when {
                anyOf {
                    expression  {
                        currentBuild.number == 1
                    }
                    expression  {
                        "${params.action}" != "destroy"
                    }
                    changeset "src/**"
                    changeset "Dockerfile"
                }
            }
            environment {
                // Config Tools
                repoSource = "${env.ansibleRepo}"

                // Docker
                registryUrl = "https://ghcr.io/v2/"
                publishedPorts = "80:8080"
            }
            steps {
                echo "Deploying App..."
                setVersion()

                sshagent(credentials: ['ansible-server-key']) {
                    sh(""" ${env.sshConnect} "
                        ${env.repoCloneCmd}
                        "
                    """)

                    withCredentials([usernamePassword(credentialsId: 'github_registry-creds', usernameVariable: 'dockerUsername', passwordVariable: 'dockerPassword')]) {
                        sh(""" ${env.sshConnect} "
                            export CUSTOM_USER="${env.customUser}"
                            export REGISTRY_URL="${env.registryUrl}"
                            export CONTAINER_NAME="${env.appName}"
                            export DOCKER_IMAGE="${env.dockerImage}:${env.versionTag}"
                            export PUBLISHED_PORTS="${env.publishedPorts}"
                            export DOCKER_USERNAME="${env.dockerUsername}"
                            export DOCKER_PASS="${env.dockerPassword}"

                            cd "${env.localVCDir}"
                            ansible-inventory -i ./inventory/inventory_aws_ec2.yaml --list | jq -r '.[].hostvars | select( . != null )[].network_interfaces[].association.public_dns_name' > publicDNS
                            ansible-playbook local.yaml --tags deployment || ${env.catchError}
                            "
                        """)
                    }
                }
            }
        }
    }
}