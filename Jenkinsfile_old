
pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/prashantmukadam16/GCP-Infracode.git'
        GIT_BRANCH = 'main'
        GOOGLE_PROJECT = 'project-88c619e6-27a3-4887-94b'

        // Use the SAME workspace as the deployment pipeline
        TF_DIR = '/var/lib/jenkins/workspace/GCP-Infracode-Pipeline/terraform'

        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Git Checkout') {
            steps {
                dir('/var/lib/jenkins/workspace/GCP-Infracode-Pipeline') {
                    git branch: "${GIT_BRANCH}",
                        url: "${GIT_REPO}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                 dir("${TF_DIR}") {
                     sh '''
                     echo "Formatting Terraform files..."

                     terraform fmt -recursive

                     echo "Checking Terraform formatting..."

                     terraform fmt -check -recursive

                     echo "Validating Terraform configuration..."

                    terraform validate
                    '''
                }
            }
    }

        stage('Verify Terraform State') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "Checking existing Terraform state..."

                        terraform state list

                        RESOURCE_COUNT=$(terraform state list | wc -l)

                        echo "Resources found in Terraform state: ${RESOURCE_COUNT}"

                        if [ "$RESOURCE_COUNT" -eq 0 ]; then
                            echo "ERROR: No Terraform resources found."
                            echo "Stopping destruction to protect infrastructure."
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Terraform Destroy Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform plan \
                          -destroy \
                          -input=false \
                          -var="project_id=${GOOGLE_PROJECT}" \
                          -out=tf-destroy.tfplan

                        terraform show -no-color tf-destroy.tfplan \
                          | tee destroy-plan.txt

                        if grep -q "No changes" destroy-plan.txt; then
                            echo "ERROR: Terraform has no resources to destroy."
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Manual Approval') {
            steps {
                script {
                    input(
                        message: 'WARNING: Review the Terraform destroy plan. This will permanently delete the managed GCP infrastructure. Proceed?',
                        ok: 'Approve Infrastructure Destruction',
                        submitter: 'YOUR_JENKINS_APPROVER'
                    )
                }
            }
        }

        stage('Terraform Destroy Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform apply \
                          -input=false \
                          tf-destroy.tfplan
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'GCP infrastructure destruction completed successfully.'
        }

        failure {
            echo 'Terraform destruction failed. Check the Jenkins console output.'
        }

        always {
            sh '''
                rm -f "${TF_DIR}/tf-destroy.tfplan"
                rm -f "${TF_DIR}/destroy-plan.txt"
            '''
        }
    }
}

