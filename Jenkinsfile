// =============================================================================
// Jenkinsfile - GCP Terraform Infrastructure Pipeline
// Project    : gcp-dev-july-2026
// Purpose    : Plan/Apply/Destroy the GCP HTTP Load Balancer Terraform stack
//
// TOOLCHAIN NOTE: This Jenkins agent has neither the "Docker Pipeline" plugin
// nor a `docker` CLI/socket available. All tooling (Terraform, Google Cloud
// SDK) is therefore installed directly on the agent inline below - no
// external scripts, no Docker. CA certificates/OpenSSL are refreshed on a
// best-effort basis only if the agent runs as root or has passwordless sudo.
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
        PATH                 = "${WORKSPACE}/.bin:${WORKSPACE}/.gcloud-sdk/google-cloud-sdk/bin:${env.PATH}"
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
                        apt-get install -y --no-install-recommends ca-certificates openssl curl wget git unzip
                        update-ca-certificates
                    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                        sudo apt-get update -qq
                        sudo apt-get install -y --no-install-recommends ca-certificates openssl curl wget git unzip
                        sudo update-ca-certificates
                    else
                        echo "WARNING: no root/sudo access on this agent - skipping OS package refresh."
                        echo "         Rebuild the Jenkins agent image with an updated base OS/OpenSSL if this is required."
                    fi

                    echo "===== Installing Terraform ${TF_VERSION} (no root required) ====="
                    if [ -x "${WORKSPACE}/.bin/terraform" ] && "${WORKSPACE}/.bin/terraform" version | grep -q "${TF_VERSION}"; then
                        echo "Terraform ${TF_VERSION} already installed."
                    else
                        curl -fsSL -o /tmp/terraform.zip \
                            "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
                        unzip -o -q /tmp/terraform.zip -d "${WORKSPACE}/.bin"
                        chmod +x "${WORKSPACE}/.bin/terraform"
                        rm -f /tmp/terraform.zip
                    fi
                    "${WORKSPACE}/.bin/terraform" version

                    echo "===== Installing Google Cloud SDK (no root required) ====="
                    if [ -x "${WORKSPACE}/.gcloud-sdk/google-cloud-sdk/bin/gcloud" ]; then
                        echo "Google Cloud SDK already installed."
                    else
                        curl -fsSL -o /tmp/gcloud.tar.gz \
                            "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"
                        mkdir -p "${WORKSPACE}/.gcloud-sdk"
                        tar -xzf /tmp/gcloud.tar.gz -C "${WORKSPACE}/.gcloud-sdk"
                        "${WORKSPACE}/.gcloud-sdk/google-cloud-sdk/install.sh" --usage-reporting=false --path-update=false --quiet
                        rm -f /tmp/gcloud.tar.gz
                    fi
                    "${WORKSPACE}/.gcloud-sdk/google-cloud-sdk/bin/gcloud" version
                '''
            }
        }

        stage('Environment & TLS Diagnostics') {
            steps {
                sh '''
                    set -euo pipefail

                    echo "===== OS Information ====="
                    cat /etc/os-release
                    uname -a

                    echo "===== Tool Versions ====="
                    terraform version
                    openssl version -a
                    gcloud --version
                    curl --version | head -n1
                    git --version

                    echo "===== Proxy / Firewall Environment Variables ====="
                    env | grep -i -E "proxy|no_proxy" || echo "No proxy variables set."

                    echo "===== DNS Resolution ====="
                    getent hosts registry.terraform.io
                    getent hosts storage.googleapis.com

                    echo "===== Basic HTTPS Connectivity ====="
                    curl -sSf -o /dev/null -w "registry.terraform.io -> HTTP %{http_code}, TLS %{tls_version}\n" https://registry.terraform.io/
                    curl -sSf -o /dev/null -w "storage.googleapis.com -> HTTP %{http_code}, TLS %{tls_version}\n" https://storage.googleapis.com/

                    echo "===== TLS 1.2 Handshake Check ====="
                    echo | openssl s_client -connect registry.terraform.io:443 -tls1_2 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true
                    echo | openssl s_client -connect storage.googleapis.com:443 -tls1_2 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true

                    echo "===== TLS 1.3 Handshake Check ====="
                    echo | openssl s_client -connect registry.terraform.io:443 -tls1_3 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true
                    echo | openssl s_client -connect storage.googleapis.com:443 -tls1_3 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true
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
