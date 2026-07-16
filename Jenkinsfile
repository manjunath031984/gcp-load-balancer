// =============================================================================
// Jenkinsfile - GCP Terraform Infrastructure Pipeline
// Project    : gcp-dev-july-2026
// Purpose    : Plan/Apply/Destroy the GCP HTTP Load Balancer Terraform stack
//
// TOOLCHAIN NOTE: The Jenkins agent's pre-installed Terraform/OpenSSL can be
// old enough to fail TLS handshakes against storage.googleapis.com
// ("remote error: tls: protocol version not supported") when reading the GCS
// state backend. The 'Install Toolchain' stage below self-installs a current,
// TLS 1.2/1.3-capable Terraform binary directly into the workspace (no root,
// no external scripts, no Docker) and prepends it to PATH so every
// subsequent `terraform` call in this pipeline uses it.
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
        PATH                 = "${WORKSPACE}/.bin:${env.PATH}"
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo "Checked out ${env.GIT_BRANCH ?: 'unknown branch'} @ ${env.GIT_COMMIT ?: 'unknown commit'}"
            }
        }

        stage('Install Toolchain') {
            steps {
                sh '''
                    set -euo pipefail
                    mkdir -p "${WORKSPACE}/.bin"

                    echo "===== Refreshing CA certificates / OpenSSL (best effort, requires root) ====="
                    if [ "$(id -u)" = "0" ]; then
                        apt-get update -qq
                        apt-get install -y --no-install-recommends ca-certificates openssl curl unzip
                        update-ca-certificates
                    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                        sudo apt-get update -qq
                        sudo apt-get install -y --no-install-recommends ca-certificates openssl curl unzip
                        sudo update-ca-certificates
                    else
                        echo "WARNING: no root/sudo access on this agent - skipping OS package refresh."
                        echo "         Terraform itself is still upgraded below, which resolves TLS"
                        echo "         handshake failures caused by an outdated Go-compiled binary."
                    fi

                    echo "===== Installing Terraform ${TF_VERSION} (self-contained, no root required) ====="
                    if [ -x "${WORKSPACE}/.bin/terraform" ] && "${WORKSPACE}/.bin/terraform" version | grep -q "${TF_VERSION}"; then
                        echo "Terraform ${TF_VERSION} already installed at ${WORKSPACE}/.bin/terraform."
                    else
                        curl -fsSL -o /tmp/terraform.zip \
                            "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
                        unzip -o -q /tmp/terraform.zip -d "${WORKSPACE}/.bin"
                        chmod +x "${WORKSPACE}/.bin/terraform"
                        rm -f /tmp/terraform.zip
                    fi

                    echo "===== Verifying TLS 1.2/1.3 connectivity to the GCS backend ====="
                    "${WORKSPACE}/.bin/terraform" version
                    openssl version
                    curl -sSf -o /dev/null -w "storage.googleapis.com -> HTTP %{http_code}, TLS %{tls_version}\n" https://storage.googleapis.com/
                '''
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
                        sh '''
                            set -euo pipefail
                            terraform apply -no-color -input=false -auto-approve tfplan.out | tee tfapply.log
                        '''
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
            // Only reached when Terraform Apply exited 0 - declarative pipeline
            // aborts subsequent stages as soon as any step throws, and the
            // pipefail fix above guarantees a failed `terraform apply` throws.
            // The explicit currentResult check is a defense-in-depth guard.
            when {
                allOf {
                    expression { return params.ACTION == 'apply' }
                    expression { return currentBuild.currentResult == 'SUCCESS' }
                }
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
            // Belt-and-suspenders: guarantee the build is marked FAILURE (not
            // left as UNSTABLE/SUCCESS) whenever any Terraform stage errors.
            script {
                currentBuild.result = 'FAILURE'
            }
            echo "Pipeline FAILED for project ${env.GOOGLE_CLOUD_PROJECT}. Review the archived tf*.log artifacts for the root cause."
        }
        cleanup {
            cleanWs(deleteDirs: true, notFailBuild: true)
        }
    }
}