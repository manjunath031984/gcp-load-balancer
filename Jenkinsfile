// =============================================================================
// Jenkinsfile - GCP Terraform Infrastructure Pipeline
// Project    : gcp-dev-july-2026
// Purpose    : Plan/Apply/Destroy the GCP HTTP Load Balancer Terraform stack
// =============================================================================

pipeline {
    // NOTE ON DOCKER USAGE: This Jenkins instance does not have the "Docker
    // Pipeline" plugin installed, so `agent { dockerfile {} }` / `agent { docker {} }`
    // are unavailable ("Invalid agent type ... Must be one of [any, label, none]").
    // Instead, the pipeline runs on `agent any` and explicitly builds/runs the
    // hardened toolchain image (see Dockerfile) via plain `docker build`/`docker run`
    // shell calls. This only requires the `docker` CLI + socket access on the
    // Jenkins agent (e.g. /var/run/docker.sock mounted into the Jenkins container).
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
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
        TF_IN_AUTOMATION     = 'true'
        TF_INPUT             = 'false'
        TOOLCHAIN_IMAGE      = "gcp-tf-agent:${env.BUILD_NUMBER}"
        DOCKER_RUN           = 'bash scripts/docker-run.sh'
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo "Checked out ${env.GIT_BRANCH ?: 'unknown branch'} @ ${env.GIT_COMMIT ?: 'unknown commit'}"
            }
        }

        stage('Build Toolchain Image') {
            steps {
                sh '''
                    set -euo pipefail
                    chmod +x scripts/*.sh
                    docker build --pull -t "${TOOLCHAIN_IMAGE}" .
                '''
            }
        }

        stage('Environment & TLS Diagnostics') {
            steps {
                sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "bash scripts/diagnostics.sh"'
            }
        }

        stage('Authenticate to GCP') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "bash scripts/gcp-auth.sh"'
                }
            }
        }

        stage('Verify Authentication') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "bash scripts/gcp-verify.sh"'
                }
            }
        }

        stage('Terraform Format') {
            steps {
                dir(params.TF_WORKING_DIR) {
                    sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "terraform fmt -check -recursive -diff"'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "terraform init -input=false -no-color"'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    dir(params.TF_WORKING_DIR) {
                        sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "terraform validate -no-color"'
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
                            ${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "terraform plan -no-color -input=false -var-file=${params.VAR_FILE} -out=tfplan.out | tee tfplan.log"
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
                        sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "terraform apply -no-color -input=false -auto-approve tfplan.out | tee tfapply.log"'
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
                            ${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "terraform destroy -no-color -input=false -auto-approve -var-file=${params.VAR_FILE} | tee tfdestroy.log"
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
                        sh '${DOCKER_RUN} "${TOOLCHAIN_IMAGE}" "echo Terraform Outputs && terraform output -no-color | tee tfoutputs.log"'
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
            sh 'docker rmi "${TOOLCHAIN_IMAGE}" || true'
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

