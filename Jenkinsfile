pipeline {

    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        PROJECT_ID = 'project-88c619e6-27a3-4887-94b'
        REGION = 'us-central1'

        TF_DIR = 'terraform'
        GKE_CLUSTER = 'gke-dev-cluster'

        SCANNER_HOME = tool 'sonar-scanner'
        MASTER_AUTHORIZED_CIDR = '34.60.89.231/32'
    }

    stages {

        // 1. Git Checkout
        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/prashantmukadam16/GCP-Infracode-DevSecOps.git'
            }
        }

        // 2. Verify Tools and Authentication
        stage('Preflight Check') {
            steps {
                sh '''
                    terraform version
                    trivy --version
                    gcloud version
                    kubectl version --client

                    gcloud config set project "$PROJECT_ID"
                    gcloud auth list
                '''
            }
        }

        // 4. Terraform Initialization and Validation
        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform init -input=false
                        terraform validate
                    '''
                }
            }
        }

        // 5. Trivy IaC Security Scan
        stage('Trivy IaC Scan') {
            steps {
                sh '''
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

        // 6. Trivy Secret Scan
        stage('Trivy Secret Scan') {
            steps {
                sh '''
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

        // 7. SonarQube Code Analysis
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        "$SCANNER_HOME/bin/sonar-scanner"
                    '''
                }
            }
        }

        // 8. SonarQube Quality Gate
        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // 9. Terraform Plan
        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform plan \
                          -input=false \
                          -var="project_id=${PROJECT_ID}" \
                          -var="master_authorized_cidr=${MASTER_AUTHORIZED_CIDR}" \
                          -out=tfplan
                    '''
                }
            }
        }

        // 10. Trivy Terraform Plan Scan
        stage('Trivy Plan Scan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
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

        // 11. Manual Approval
        stage('Infrastructure Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Approve GCP infrastructure deployment?',
                          ok: 'Deploy Infrastructure'
                }
            }
        }

        // 12. Terraform Apply
        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform apply \
                          -input=false \
                          -auto-approve \
                          tfplan
                    '''
                }
            }
        }

        // 13. Connect to GKE
        stage('GKE Authentication') {
            steps {
                sh '''
                    gcloud container clusters get-credentials \
                      "$GKE_CLUSTER" \
                      --region "$REGION" \
                      --project "$PROJECT_ID"

                    kubectl get nodes
                '''
            }
        }

        // 14. Install Argo CD
        stage('Install Argo CD') {
            steps {
                sh '''
                    if ! kubectl get namespace argocd >/dev/null 2>&1; then
                        kubectl create namespace argocd
                    fi

                    kubectl apply -n argocd \
                      --server-side \
                      --force-conflicts \
                      -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.2.0/manifests/install.yaml

                    kubectl wait \
                      --for=condition=Established \
                      --timeout=120s \
                      crd/applications.argoproj.io
                '''
            }
        }

        // 15. Argo CD GitOps Deployment
        stage('Argo CD GitOps Deployment') {
            steps {
                sh '''
                    kubectl apply -f argocd/application.yaml

                    kubectl wait \
                      --for=condition=Available \
                      deployment/nginx-deployment \
                      -n devops-demo \
                      --timeout=300s
                '''
            }
        }

        // 16. Final Verification
        stage('Deployment Verification') {
            steps {
                sh '''
                    echo "GKE Cluster:"
                    kubectl get nodes

                    echo "Kubernetes Deployments:"
                    kubectl get deployments -n devops-demo

                    echo "Kubernetes Services:"
                    kubectl get services -n devops-demo

                    echo "Argo CD Applications:"
                    kubectl get applications -n argocd
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
            echo 'GCP infrastructure and GKE GitOps deployment completed!'
        }

        failure {
            echo 'Pipeline failed. Review Jenkins console output and security reports.'
        }
    }
}
