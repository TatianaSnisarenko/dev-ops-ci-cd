pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command:
        - sleep
      args:
        - 99d
    - name: git
      image: alpine/git
      command:
        - sleep
      args:
        - 99d
"""
    }
  }

  environment {
    ECR_REPOSITORY = "989496898833.dkr.ecr.eu-north-1.amazonaws.com/lab-ecr"
    IMAGE_TAG      = "v1.0.${BUILD_NUMBER}"

    COMMIT_EMAIL = "jenkins@localhost"
    COMMIT_NAME  = "jenkins"

    INFRA_REPO_URL = "https://github.com/TatianaSnisarenko/dev-ops-ci-cd.git"
  }

  stages {
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --context ${WORKSPACE}/django \
              --dockerfile ${WORKSPACE}/Dockerfile \
              --destination=$ECR_REPOSITORY:$IMAGE_TAG \
              --cache=true \
              --insecure \
              --skip-tls-verify
          '''
        }
      }
    }

    stage('Update Chart Tag in Git') {
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'github-token',
                                           usernameVariable: 'GIT_USERNAME',
                                           passwordVariable: 'GIT_PAT')]) {
            sh '''
              git clone https://$GIT_USERNAME:$GIT_PAT@${INFRA_REPO_URL#https://}
              cd dev-ops-ci-cd

              cd charts/django-app

              sed -i "s/^  tag: .*/  tag: $IMAGE_TAG/" values.yaml

              git config user.email "$COMMIT_EMAIL"
              git config user.name "$COMMIT_NAME"

              git add values.yaml
              git commit -m "Update image tag to $IMAGE_TAG" || echo "Nothing to commit"
              git push origin main
            '''
          }
        }
      }
    }
  }
}
