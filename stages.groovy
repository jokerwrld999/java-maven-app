def deployApp() {
    echo "Deploying app on the EC2 server..."
    def ec2InstanceIP = 'ec2-user@18.184.222.61'
    def executeScript ="bash ./deploy_app.sh $imageName:${versionTag}"
    sshagent(credentials: ['ec2-private-key']) {
      sh "scp -o StrictHostKeyChecking=no deploy_app.sh docker-compose.yaml ${ec2InstanceIP}:/home/ec2-user"
      sh "ssh -o StrictHostKeyChecking=no ${ec2InstanceIP} ${executeScript}"
    }
}

return this