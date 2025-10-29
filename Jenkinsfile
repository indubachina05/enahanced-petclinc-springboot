pipeline {
  agent any
  tools {
    maven 'Maven 3.9.11'
  }
  environment {
    REGISTRY = "luckyregistryindu.azurecr.io"
    IMAGE_NAME = "petclinic"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    ACR_CREDS = credentials('acr-admin')      // Add Docker/ACR creds in Jenkins
    AZURE_SP = credentials('azure-sp-creds')  // clientId:clientSecret style or full JSON
    SONAR_TOKEN = credentials('sonarcloud-token')
    AZURE_SUBSCRIPTION = "16627783-b6dd-49c9-9545-dc269621eb66"
    RESOURCE_GROUP = "demo11"
    AKS_NAME = "lucky-aks-cluster11"
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
        withEnv(["SONAR_TOKEN=${SONAR_TOKEN}"]) {
          sh '''
            mvn sonar:sonar \
              -Dsonar.projectKey=petclinic \
              -Dsonar.host.url=https://sonarcloud.io \
              -Dsonar.login=$SONAR_TOKEN
          '''
        }
      }
    }

    stage('Docker Build & Push') {
      steps {
        script {
          // login to ACR (admin user or use az acr login)
          sh "docker login ${REGISTRY} -u ${ACR_CREDS_USR} -p ${ACR_CREDS_PSW}" // or use az acr login
          sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ."
          sh "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        }
      }
    }

    stage('Deploy to AKS') {
      steps {
        script {
          // login to azure using service principal
          sh """
            az login --service-principal -u ${AZURE_SP_USR} -p ${AZURE_SP_PSW} --tenant ${AZURE_SP_TENANT}
            az account set --subscription ${AZURE_SUBSCRIPTION}
            az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_NAME} --overwrite-existing
          """

          // create/update Kubernetes deployment and service (simple example)
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

  post {
    always {
      echo "Pipeline finished"
    }
  }
}
