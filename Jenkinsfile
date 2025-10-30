pipeline {
    agent any

    tools {
        maven 'Maven 3.9.11'
    }

    environment {
        REGISTRY           = "luckyregistryindu.azurecr.io"
        IMAGE_NAME         = "petclinic"
        IMAGE_TAG          = "${env.BUILD_NUMBER}"
        SONAR_TOKEN        = credentials('sonarcloud-token')
        AZURE_SUBSCRIPTION = "16627783-b6dd-49c9-9545-dc269621eb66"
        RESOURCE_GROUP     = "demo11"
        AKS_NAME           = "lucky-aks-cluster11"
        DOCKER_BUILDKIT    = "1"  // Enable BuildKit
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn -B -DskipTests=false clean package'
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarcloud-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn -B sonar:sonar \
                          -Dsonar.projectKey=indubachina05_enahanced-petclinc-springboot \
                          -Dsonar.organization=indubachina05 \
                          -Dsonar.host.url=https://sonarcloud.io \
                          -Dsonar.login=$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'acr-admin',
                                                     usernameVariable: 'ACR_CREDS_USR',
                                                     passwordVariable: 'ACR_CREDS_PSW')]) {
                        sh """
                            export DOCKER_BUILDKIT=1
                            docker login ${REGISTRY} -u $ACR_CREDS_USR -p $ACR_CREDS_PSW
                            docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                            docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'azure-sp-creds',
                                                 usernameVariable: 'AZURE_SP_USR',
                                                 passwordVariable: 'AZURE_SP_PSW')]) {
                    script {
                        sh """
                            az login --service-principal -u $AZURE_SP_USR -p $AZURE_SP_PSW --tenant da8b75ec-6e72-4789-90f1-b203e7abed5e
                            az account set --subscription ${AZURE_SUBSCRIPTION}
                            az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_NAME} --overwrite-existing
                        """

                        sh """
cat > k8s-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: petclinic
  template:
    metadata:
      labels:
        app: petclinic
    spec:
      containers:
      - name: petclinic
        image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: petclinic-service
spec:
  type: LoadBalancer
  selector:
    app: petclinic
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
EOF

kubectl apply -f k8s-deployment.yaml
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished"
        }
        failure {
            echo "Pipeline failed! Check logs for details."
        }
    }
}
