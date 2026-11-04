pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        GIT_REPO         = 'https://github.com/prashantmukadam16/GCP-Infracode.git'
        GIT_BRANCH       = 'main'
        GOOGLE_PROJECT   = 'project-88c619e6-27a3-4887-94b'
        REGION           = 'us-central1'
        GKE_CLUSTER      = 'gke-dev'
        TF_DIR           = 'terraform'
        TF_IN_AUTOMATION = 'true'
        TF_INPUT         = 'false'
        ARGOCD_VERSION   = 'v3.2.0'
        SCANNER_HOME     = tool 'sonar-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Preflight') {
            steps {
                sh '''
                    set -eu
                    terraform version
                    trivy --version
                    gcloud version
                    kubectl version --client
                    gke-gcloud-auth-plugin --version
                    gcloud config set project "$GOOGLE_PROJECT"
                    gcloud auth list
                '''
            }
        }

        stage('Terraform Format') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform fmt -check -recursive'
                }
            }
        }

        stage('Terraform Init and Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform init -input=false
                        terraform validate
                    '''
                }
            }
        }

        stage('Trivy IaC Scan') {
            steps {
                sh '''
                    set -eu
                    trivy config \
                      --skip-dirs .git \
                      --skip-dirs terraform/.terraform \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --format json \
                      --output "$WORKSPACE/trivy-iac.json" \
                      .
                '''
            }
        }

        stage('Trivy Secret Scan') {
            steps {
                sh '''
                    set -eu
                    trivy fs \
                      --scanners secret \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --format json \
                      --output "$WORKSPACE/trivy-secrets.json" \
                      .
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '"$SCANNER_HOME/bin/sonar-scanner"'
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform plan \
                          -input=false \
                          -var-file="terraform.tfvars.example" \
                          -out=tfplan
                    '''
                }
            }
        }

        stage('Trivy Terraform Plan Scan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        set -eu
                        trivy config \
                          --severity HIGH,CRITICAL \
                          --exit-code 1 \
                          --format json \
                          --output "$WORKSPACE/trivy-plan.json" \
                          tfplan.json
                    '''
                }
            }
        }

        stage('Review and Approve Plan') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Review the Terraform plan. Approve GCP infrastructure deployment?',
                          ok: 'Approve and Apply'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }

        stage('Connect to GKE') {
            steps {
                sh '''
                    set -eu
                    gcloud container clusters get-credentials "$GKE_CLUSTER" \
                      --region "$REGION" \
                      --project "$GOOGLE_PROJECT"
                    kubectl get nodes
                '''
            }
        }

        stage('Install or Update Argo CD') {
            steps {
                sh '''
                    set -eu
                    kubectl create namespace argocd \
                      --dry-run=client -o yaml | kubectl apply -f -

                    kubectl apply --server-side --force-conflicts \
                      -n argocd \
                      -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

                    kubectl rollout status deployment/argocd-server \
                      -n argocd --timeout=600s
                    kubectl rollout status deployment/argocd-repo-server \
                      -n argocd --timeout=600s
                    kubectl rollout status statefulset/argocd-application-controller \
                      -n argocd --timeout=600s
                '''
            }
        }

        stage('Register GitOps Application') {
            steps {
                sh '''
                    set -eu
                    kubectl apply -f argocd/application.yaml

                    kubectl wait \
                      --for=jsonpath='{.status.sync.status}'=Synced \
                      application/gcp-infracode-app \
                      -n argocd \
                      --timeout=600s

                    kubectl wait \
                      --for=jsonpath='{.status.health.status}'=Healthy \
                      application/gcp-infracode-app \
                      -n argocd \
                      --timeout=600s
                '''
            }
        }

        stage('Deployment Verification') {
            steps {
                sh '''
                    set -eu
                    kubectl get nodes
                    kubectl get applications -n argocd
                    kubectl get deployments,pods,services -n devops-demo

                    kubectl wait \
                      --for=condition=Available \
                      deployment/nginx-deployment \
                      -n devops-demo \
                      --timeout=300s
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-*.json',
                allowEmptyArchive: true

            sh '''
                rm -f terraform/tfplan terraform/tfplan.json
            '''
        }
        success {
            echo 'GCP infrastructure provisioning and Argo CD GitOps deployment completed.'
        }
        failure {
            echo 'Pipeline failed. Review Jenkins console output and archived security reports.'
        }
    }
}
