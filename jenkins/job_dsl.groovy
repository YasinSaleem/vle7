job('vle7-app-pipeline') {
    description('VLE7 Blue-Green Deployment Pipeline - Automated Setup')
    
    parameters {
        choiceParam('DEPLOYMENT_COLOR', ['blue', 'green'], 'Choose deployment color for blue-green deployment')
        booleanParam('SKIP_DOCKER_BUILD', false, 'Skip Docker build and use existing image')
    }
    
    scm {
        git {
            remote {
                url('https://github.com/YasinSaleem/vle7.git')
                credentials('github-credentials') // You'll need to add this manually
            }
            branch('main')
        }
    }
    
    triggers {
        githubPush()
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/YasinSaleem/vle7.git')
                    }
                    branch('main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
    
    logRotator {
        numToKeep(10)
        daysToKeep(30)
    }
}