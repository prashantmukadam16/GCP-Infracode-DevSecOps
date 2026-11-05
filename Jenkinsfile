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
        GKE_CLUSTER = 'gke-uat'

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
                    set -eu

                    echo "Removing stale Terraform plan artifacts..."
                    rm -f terraform/tfplan \
                        terraform/tfplan.json \
                        terraform/tfplan.tfplan.json

                    echo "Running Trivy source IaC scan..."

                    trivy config \
                    --skip-dirs .git \
                    --skip-dirs terraform/.terraform \
                    --skip-files terraform/tfplan.tfplan.json \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    --format json \
                    --output trivy-iac.json \
                    .

                    echo "Checking Trivy findings..."
                    jq -r '
                    .Results[]? as $r
                    | $r.Misconfigurations[]?
                    | [
                        $r.Target,
                        $r.Type,
                        .Severity,
                        .ID,
                        .Title
                        ]
                    | @tsv
                    ' trivy-iac.json
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
                        set -eu

                        terraform plan \
                        -input=false \
                        -var="project_id=${PROJECT_ID}" \
                        -var="master_authorized_cidr=${MASTER_AUTHORIZED_CIDR}" \
                        -out=tfplan

                        terraform show -json tfplan > tfplan.tfplan.json

                        echo "Validating Cloud SQL security settings..."

                        jq -e '
                        ([.resource_changes[]
                            | select(
                                .address ==
                                "module.mysql.google_sql_database_instance.mysql"
                            )
                        ][0]) as $r

                        | ($r != null)
                            and (
                            $r.change.after.settings[0]
                                .ip_configuration[0].ipv4_enabled == false
                            )
                            and (
                            $r.change.after.settings[0]
                                .ip_configuration[0].ssl_mode == "ENCRYPTED_ONLY"
                            )
                            and (
                            (
                                $r.change.after.settings[0]
                                .ip_configuration[0].authorized_networks // []
                            ) | length == 0
                            )
                        ' tfplan.tfplan.json

                        echo "Validating private VPC network wiring..."

                        jq -e '
                        .configuration.root_module.module_calls.mysql
                        as $mysql

                        | (
                            $mysql.expressions.network_id.references
                            | index("module.network.network_id")
                            ) != null

                        and (
                            [
                            $mysql.module.resources[]
                            | select(
                                .type == "google_sql_database_instance"
                                and .name == "mysql"
                                )
                            | .expressions.settings[0]
                                .ip_configuration[0]
                            ][0]
                            | (.ipv4_enabled.constant_value == false)
                            and (.ssl_mode.constant_value == "ENCRYPTED_ONLY")
                            and (
                                (.private_network.references // [])
                                | index("var.network_id") != null
                            )
                        )
                        ' tfplan.tfplan.json

                        echo "Cloud SQL security validation passed."
                    '''
                }
            }
        }

        // 10. Trivy Terraform Plan Scan
        stage('Trivy Plan Scan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        set -eu

                        trivy config \
                        --misconfig-scanners terraformplan-json \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format json \
                        --output "$WORKSPACE/trivy-plan-report.json" \
                        tfplan.tfplan.json

                        echo "Trivy plan scan completed. Review its report alongside the Cloud SQL security validation."
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
                    set -eu

                    echo "Checking Argo CD namespace..."

                    if ! kubectl get namespace argocd >/dev/null 2>&1; then
                        kubectl create namespace argocd
                    else
                        echo "Argo CD namespace already exists. Skipping creation."
                    fi

                    echo "Installing or updating Argo CD..."

                    kubectl apply -n argocd \
                    --server-side \
                    --force-conflicts \
                    -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.2.0/manifests/install.yaml

                    echo "Waiting for Argo CD CRD..."

                    kubectl wait \
                    --for=condition=Established \
                    --timeout=120s \
                    crd/applications.argoproj.io

                    echo "Waiting for Argo CD server..."

                    kubectl rollout status \
                    deployment/argocd-server \
                    -n argocd \
                    --timeout=300s

                    echo "Waiting for Argo CD application controller..."

                    kubectl rollout status \
                    statefulset/argocd-application-controller \
                    -n argocd \
                    --timeout=300s

                    echo "Argo CD installation completed."
                '''
            }
        }

        // 15. Argo CD GitOps Deployment
        stage('Argo CD GitOps Deployment') {
            steps {
                sh '''
                    set -eu

                    echo "Checking Argo CD Application CRD..."
                    kubectl get crd applications.argoproj.io

                    echo "Checking target namespace..."

                    if ! kubectl get namespace devops-demo >/dev/null 2>&1; then
                        kubectl create namespace devops-demo
                    else
                        echo "Namespace already exists. Skipping creation."
                    fi

                    echo "Applying Argo CD Application..."
                    kubectl apply -f argocd/application.yaml

                    echo "Waiting for Argo CD synchronization..."

                    if ! kubectl wait \
                        --for=jsonpath='{.status.sync.status}'=Synced \
                        application/gcp-infracode-app \
                        -n argocd \
                        --timeout=600s; then

                        echo "Argo CD synchronization failed. Application details:"
                        kubectl get application gcp-infracode-app -n argocd -o yaml
                        exit 1
                    fi

                    echo "Waiting for application health..."

                    if ! kubectl wait \
                        --for=jsonpath='{.status.health.status}'=Healthy \
                        application/gcp-infracode-app \
                        -n argocd \
                        --timeout=600s; then

                        echo "Application health check failed:"
                        kubectl get application gcp-infracode-app -n argocd -o yaml
                        exit 1
                    fi

                    echo "Checking NGINX deployment..."

                    kubectl rollout status \
                        deployment/nginx-deployment \
                        -n devops-demo \
                        --timeout=300s

                    echo "GitOps deployment completed successfully."
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
                rm -f terraform/tfplan \
                    terraform/tfplan.json \
                    terraform/tfplan.tfplan.json
            '''
        }

        success {
            echo 'GCP infrastructure and GKE GitOps deployment completed!'
        }

        failure {
            echo 'Pipeline failed. Review Jenkins console output and security reports.'
        }
    }
