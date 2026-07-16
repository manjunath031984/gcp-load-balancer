// =============================================================================
// Jenkinsfile - GCP Terraform Infrastructure Pipeline
// Project    : gcp-dev-july-2026
// Purpose    : Plan/Apply/Destroy the GCP HTTP Load Balancer Terraform stack
//
// TOOLCHAIN NOTE: This pipeline assumes Terraform and the Google Cloud SDK
// are already installed and available on the Jenkins agent's PATH.
// =============================================================================

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 60, unit: 'MINUTES')
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Select whether to apply or destroy the Terraform-managed infrastructure.'
        )
        string(
            name: 'TF_WORKING_DIR',
            defaultValue: '.',
            description: 'Relative path to the Terraform root module.'
        )
        string(
            name: 'VAR_FILE',
            defaultValue: 'terraform.tfvars',
            description: 'Terraform var file to use for plan/apply/destroy.'
        )
    }

    environment {
        GOOGLE_CLOUD_PROJECT = 'gcp-dev-july-2026'
        REGION               = 'us-central1'
        ZONE                 = 'us-central1-a'
        TF_VERSION           = '1.13.0'
        TF_IN_AUTOMATION     = 'true'
        TF_INPUT             = 'false'
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo "Checked out ${env.GIT_BRANCH ?: 'unknown branch'} @ ${env.GIT_COMMIT ?: 'unknown commit'}"
            }
        }

        stage('Authenticate to GCP') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        set -euo pipefail
                        gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
                        gcloud config set project "$GOOGLE_CLOUD_PROJECT"
                    '''
                }
            }
        }

        stage('Verify Authentication') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        set -euo pipefail
                        echo "===== Active gcloud accounts ====="
                        gcloud auth list
                        echo "===== Active gcloud configuration ====="
                        gcloud config list
                    '''
                }
            }
        }

        stage('Terraform Format') {
            steps {
                dir(params.TF_WORKING_DIR) {
                    sh 'terraform fmt -check -recursive -diff'
                }
            }
        }
         stage('Registry Connectivity Check') {
            steps {
                sh '''
                    set +e
                    echo "Checking outbound access to registry.terraform.io ..."
                    if command -v getent >/dev/null 2>&1; then
                        getent hosts registry.terraform.io || echo "WARNING: DNS resolution failed for registry.terraform.io"
                    fi
                    curl -sS --max-time 10 -o /dev/null -w "registry.terraform.io -> HTTP %{http_code}\\n" https://registry.terraform.io/.well-known/terraform.json
                    status=$?
                    if [ $status -ne 0 ]; then
                        echo "ERROR: Could not reach registry.terraform.io (curl exit code $status)."
                        echo "Check agent egress/firewall rules, or set HTTPS_PROXY/HTTP_PROXY/NO_PROXY if this agent requires a proxy."
                        exit 1
                    fi
                    echo "Proxy env vars: http_proxy=$http_proxy https_proxy=$https_proxy no_proxy=$no_proxy"
                '''
            }
        }


        stage('Terraform Init') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh 'terraform init -input=false -no-color'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh 'terraform validate -no-color'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh """
                            set -euo pipefail
                            terraform plan -no-color -input=false \
                                -var-file="${params.VAR_FILE}" \
                                -out=tfplan.out | tee tfplan.log
                        """
                    }
                }
            }
        }

        stage('Manual Approval before Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                script {
                    timeout(time: 30, unit: 'MINUTES') {
                        input message: "Apply Terraform plan for ${env.GOOGLE_CLOUD_PROJECT}?", ok: 'Apply'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh 'terraform apply -no-color -input=false -auto-approve tfplan.out | tee tfapply.log'
                    }
                }
            }
        }

        stage('Manual Approval before Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
                script {
                    timeout(time: 30, unit: 'MINUTES') {
                        input message: "Confirm terraform destroy for ${env.GOOGLE_CLOUD_PROJECT}?", ok: 'Destroy'
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh """
                            set -euo pipefail
                            terraform destroy -no-color -input=false -auto-approve \
                                -var-file="${params.VAR_FILE}" | tee tfdestroy.log
                        """
                    }
                }
            }
        }

        stage('Display Terraform Outputs') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh '''
                            set -euo pipefail
                            echo "===== Terraform Outputs ====="
                            terraform output -no-color | tee tfoutputs.log
                        '''
                    }
                }
            }
        }

        stage('Workspace Cleanup') {
            steps {
                dir(params.TF_WORKING_DIR) {
                    sh '''
                        set -euo pipefail
                        rm -rf .terraform
                        echo "Local .terraform directory removed. Cleanup complete."
                    '''
                }
            }
        }
    }

    post {
        always {
            dir(params.TF_WORKING_DIR) {
                archiveArtifacts artifacts: 'tfplan.out, tfplan.log, tfapply.log, tfdestroy.log, tfoutputs.log',
                                  allowEmptyArchive: true,
                                  fingerprint: true
            }
        }
        success {
            echo "Pipeline completed successfully for project ${env.GOOGLE_CLOUD_PROJECT}."
        }
        failure {
            echo "Pipeline failed. Review the archived logs for details."
        }
        cleanup {
            cleanWs(deleteDirs: true, notFailBuild: true)
        }
    }
}