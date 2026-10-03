# AWS DevOps Platform — Troubleshooting Documentation

This document records the main technical problems encountered during the development, configuration, deployment, testing, and validation of the AWS DevOps Platform.

Each section documents the problem, investigation, root cause, solution, and lesson learned.

---

# 1. Terraform and Infrastructure

## 1.1 EKS API DNS Failure and Terraform Tainted Resource

### Problem

During Terraform operations, communication with the EKS API endpoint temporarily failed because of a DNS/network resolution problem.

Terraform subsequently marked the EKS resource as tainted and planned to replace the cluster.

### Investigation

The actual EKS cluster state was checked directly using the AWS CLI and the cluster was confirmed to be `ACTIVE`.

DNS resolution was also tested:

    nslookup <EKS_ENDPOINT>

The issue was determined to be temporary DNS/network communication rather than an actual EKS cluster failure.

### Solution

The Terraform resource was untainted instead of unnecessarily destroying and recreating the EKS cluster:

    terraform untaint <resource>

Terraform was then run again.

### Lesson Learned

Terraform state and the actual AWS resource state should both be checked before performing destructive operations.

A temporary API or DNS failure can cause Terraform to interpret an existing healthy resource incorrectly.

---

## 1.2 Terraform State vs Actual AWS Infrastructure

### Problem

Terraform sometimes indicated that an AWS resource required changes or replacement even though the resource still existed and was operational in AWS.

### Investigation

Terraform state was inspected:

    terraform state list
    terraform state show <resource>

The corresponding AWS resource was then checked using the AWS CLI or AWS Console.

### Solution

The actual AWS resource state was verified before accepting destructive Terraform changes.

### Lesson Learned

Terraform state represents Terraform's view of the infrastructure, while AWS represents the actual deployed infrastructure.

When Terraform reports unexpected changes, both should be compared before proceeding.

---

## 1.3 Terraform Remote State and Infrastructure Organization

### Problem

As the project grew, managing the VPC, EKS, database, and load balancer infrastructure together became harder to maintain.

### Solution

Terraform was separated into independent stacks:

    terraform/
    ├── vpc/
    ├── eks/
    ├── database/
    └── loadbalancer/

Each stack uses a separate S3 state key:

    vpc/terraform.tfstate
    eks/terraform.tfstate
    database/terraform.tfstate
    loadbalancer/terraform.tfstate

Terraform remote state was used to pass required outputs between the stacks.

The resulting dependency flow is:

    VPC
      ↓
    EKS
      ↓
    Database
      ↓
    Load Balancer

### Lesson Learned

Separating infrastructure into logical Terraform stacks makes dependencies easier to understand and allows individual infrastructure components to be managed independently.

---

# 2. Jenkins and CI/CD

## 2.1 Jenkins Temporary Directory and Disk Space

### Problem

Jenkins encountered a disk-space threshold problem involving `/tmp`.

### Investigation

Disk usage was checked using:

    df -h

Temporary storage and generated build artifacts were investigated.

### Solution

Unnecessary temporary files and build artifacts were removed.

Docker cleanup was also incorporated into the Jenkins pipeline where appropriate.

### Lesson Learned

CI/CD servers continuously generate build artifacts, Docker layers, logs, temporary files, and security scanner data.

Disk usage should therefore be monitored and cleaned regularly.

---

## 2.2 Java Version Mismatch

### Problem

The Jenkins/Maven environment initially had a Java version compatibility problem.

### Investigation

The Java version was checked:

    java -version

Maven's Java environment was checked:

    mvn -version

### Solution

The correct Java version was installed and configured for the Jenkins environment.

### Lesson Learned

For Java-based CI/CD pipelines, the Java version used by Jenkins, Maven, the application, and the container runtime should be checked when investigating build failures.

---

## 2.3 Jenkins Docker Permissions

### Problem

Docker was installed and working on the Jenkins VM, but the Jenkins user could not initially communicate with the Docker daemon.

### Investigation

Docker was tested from the Jenkins user's environment:

    docker ps

Docker socket permissions and group membership were checked.

### Solution

The Jenkins user was given the required Docker permissions.

### Lesson Learned

Installing Docker does not automatically give every Linux user permission to use the Docker daemon.

CI users such as Jenkins require explicit access.

---

## 2.4 Ubuntu and Docker Repository Date Problem

### Problem

Package installation encountered an Ubuntu/Docker repository `InRelease` date/time-related error.

### Investigation

The server's system date and time were checked.

The repository metadata appeared invalid because the system time was incorrect.

### Solution

The system date/time was corrected and package installation was retried.

### Lesson Learned

When APT reports repository metadata or `InRelease` validity problems, check the server's system time before changing repository configuration.

---

## 2.5 Jenkins and PetClinic Port 8080 Conflict

### Problem

The PetClinic Docker container initially attempted to use host port `8080`, while Jenkins was already using port `8080`.

### Symptoms

Docker could not bind the requested host port.

### Investigation

The port was checked:

    sudo ss -tulpn | grep 8080

Jenkins was found to be listening on port `8080`.

### Solution

The PetClinic container continued to use port `8080` internally, but a different host port was used when running the container locally.

### Lesson Learned

Container ports and host ports are separate.

An application can listen on:

    Container: 8080

while using a different host port to avoid conflicts.

---

## 2.6 ECR Authentication from Jenkins

### Problem

Jenkins needed to authenticate with Amazon ECR before pushing Docker images.

### Solution

The pipeline used AWS CLI authentication:

    aws ecr get-login-password --region ${AWS_REGION} |
    docker login --username AWS --password-stdin ${REGISTRY_URL}

The Docker image was then pushed to ECR.

### Result

Jenkins successfully built, authenticated, and pushed the application image to ECR.

### Lesson Learned

Container registry authentication must be completed before attempting to push an image.

The CI/CD sequence is:

    Build
      ↓
    Docker Image
      ↓
    ECR Authentication
      ↓
    ECR Push

---

## 2.7 Missing `eks:DescribeCluster` Permission

### Problem

The Jenkins pipeline could authenticate to AWS but could not successfully execute:

    aws eks update-kubeconfig

### Cause

The Jenkins IAM identity did not have:

    eks:DescribeCluster

permission.

### Solution

The required EKS permission was added to the Jenkins IAM policy.

### Lesson Learned

AWS authentication and authorization are different.

Successfully authenticating with AWS does not mean an IAM identity has permission to perform every required operation.

---

## 2.8 Namespace-Scoped EKS Permissions

### Problem

Jenkins could interact with the PetClinic namespace but received a forbidden error when attempting:

    kubectl get nodes

### Cause

The Jenkins identity was intentionally configured with namespace-scoped permissions rather than cluster-wide administrative permissions.

### Expected Behavior

Jenkins could perform deployment-related operations such as:

    kubectl get pods -n petclinic
    kubectl rollout status deployment/petclinic -n petclinic
    kubectl set image deployment/petclinic ...

but cluster-wide operations such as:

    kubectl get nodes

were not permitted.

### Lesson Learned

CI/CD systems should receive only the Kubernetes permissions required to perform deployments.

Cluster-admin access should not be granted simply to eliminate permission errors.

---

# 3. Security Scanning

## 3.1 Maven Dependency Vulnerabilities

### Problem

Trivy detected HIGH/CRITICAL vulnerabilities in application dependencies during the filesystem scan.

### Investigation

The project was scanned using:

    trivy fs --scanners vuln --severity HIGH,CRITICAL .

The vulnerable dependencies were identified.

### Solution

The affected dependencies were upgraded.

Examples included:

    Tomcat
    11.0.22 → 11.0.25

    PostgreSQL JDBC
    42.7.11 → 42.7.12

The filesystem scan was then repeated.

### Result

The HIGH/CRITICAL dependency findings were resolved.

### Lesson Learned

Security scanning should occur before the image reaches the container registry.

Dependency vulnerabilities should be fixed at the source rather than ignored by the pipeline.

---

## 3.2 Docker Base Image Vulnerabilities

### Problem

Trivy detected vulnerabilities in the Docker image that were not directly caused by PetClinic application code.

### Investigation

The vulnerabilities were traced to the Java base image.

The original Dockerfile used:

    FROM eclipse-temurin:17-jre

### Solution

The base image was changed to:

    FROM eclipse-temurin:17-jre-noble

The image was rebuilt and scanned again.

### Result

The resulting image passed the configured HIGH/CRITICAL vulnerability gate.

### Lesson Learned

Container security scanning covers the entire image:

    Application
        +
    Dependencies
        +
    Base Operating System
        +
    Runtime
        =
    Final Container Image

Base image selection is therefore part of container security.

---

# 4. Database and Application

## 4.1 PostgreSQL Tables Did Not Exist

### Problem

PetClinic successfully connected to AWS RDS PostgreSQL, but the application failed with errors such as:

    relation "vets" does not exist
    relation "owners" does not exist

### Investigation

The RDS connection itself was confirmed to be working.

The application container and environment variables were inspected.

The PostgreSQL Spring profile was not active.

### Cause

The application was not running with:

    SPRING_PROFILES_ACTIVE=postgres

### Solution

The Deployment was updated with:

    env:
      - name: SPRING_PROFILES_ACTIVE
        value: postgres

The application was restarted.

### Result

Spring Boot initialized the PostgreSQL schema and PetClinic successfully used RDS.

### Lesson Learned

A successful database network connection does not necessarily mean the application is correctly configured for that database.

Network connectivity and application configuration must both be verified.

---

## 4.2 PostgreSQL Password Authentication Failure

### Problem

PetClinic repeatedly failed to authenticate against RDS PostgreSQL even though the password came directly from Terraform.

### Cause

The Terraform-generated PostgreSQL password contained special characters, including `$`.

The Kubernetes Secret was created from PowerShell using double quotes.

PowerShell interpreted `$` as variable expansion rather than treating it as part of the password.

This resulted in the wrong password being stored in the Kubernetes Secret.

### Solution

The Secret was recreated using single quotes around the password:

    kubectl create secret generic petclinic-db `
      -n petclinic `
      --from-literal=SPRING_DATASOURCE_USERNAME='petclinicadmin' `
      --from-literal=SPRING_DATASOURCE_PASSWORD='PASSWORD' `
      --from-literal=SPRING_DATASOURCE_URL='jdbc:postgresql://YOUR_RDS_ENDPOINT:5432/petclinic'

The deployment was restarted:

    kubectl rollout restart deployment petclinic -n petclinic

### Result

PetClinic successfully authenticated with PostgreSQL.

### Lesson Learned

When passing credentials containing special characters through PowerShell, use single quotes to preserve the password exactly.

Credentials must never be committed to Git.

---

## 4.3 RDS and EKS Security Group Connectivity

### Design

The PostgreSQL RDS instance was deployed privately.

Its security group allows PostgreSQL traffic on port `5432` from the EKS worker-node security group.

The intended traffic flow is:

    PetClinic Pod
         ↓
    EKS Node
         ↓
    RDS Security Group
         ↓
    PostgreSQL :5432

RDS was configured as:

    publicly_accessible = false

### Lesson Learned

Database access should be restricted to workloads that require it instead of exposing PostgreSQL publicly.

Security groups provide network-level access control between the EKS workloads and RDS.

---

# 5. Kubernetes and AWS Load Balancer

## 5.1 AWS Load Balancer Controller and ALB

### Problem

The PetClinic application needed external access through an AWS Application Load Balancer.

This required correct coordination between:

- EKS
- AWS Load Balancer Controller
- IAM
- OIDC
- Kubernetes Ingress
- VPC subnet tags
- Security groups

### Solution

The AWS Load Balancer Controller was deployed with the required IAM permissions and service account configuration.

The Kubernetes Ingress used:

    spec:
      ingressClassName: alb

with annotations including:

    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip

### Result

The PetClinic Service became accessible through an AWS Application Load Balancer.

### Lesson Learned

AWS load balancer provisioning from Kubernetes depends on both AWS infrastructure and Kubernetes configuration.

When troubleshooting ALB provisioning, both layers should be checked.

---

## 5.2 Kubernetes Deployment Rollout and Health Verification

### Problem

A successful Kubernetes image update does not necessarily mean the new application version is healthy.

### Solution

The Jenkins pipeline verifies the deployment rollout:

    kubectl rollout status deployment/petclinic -n petclinic

The Deployment also uses readiness and liveness probes.

### Result

The pipeline waits for Kubernetes to confirm that the new version has successfully rolled out.

### Lesson Learned

A CI/CD pipeline should verify the result of a deployment rather than assuming that submitting the Kubernetes update means the application is healthy.

---

# 6. Monitoring and Alerting

## 6.1 Missing PetClinic-Specific PrometheusRule

### Problem

Prometheus and Grafana were running correctly, but scaling PetClinic to zero did not initially generate the desired application-specific alert.

### Cause

The monitoring stack contained default Kubernetes monitoring rules, but there was no custom rule describing the PetClinic availability condition.

### Solution

A Kubernetes `PrometheusRule` resource was created containing application-specific alerts:

    PetClinicDeploymentUnavailable
    PetClinicPodRestarting
    PetClinicDeploymentReplicasMismatch

Example:

    - alert: PetClinicDeploymentUnavailable
      expr: |
        kube_deployment_status_replicas_available{
          namespace="petclinic",
          deployment="petclinic"
        } == 0
      for: 30s

The custom rule was applied separately using:

    kubectl apply -f petclinic-alerts.yaml

### Result

Prometheus detected the application condition and the alert entered the `FIRING` state.

### Lesson Learned

The Helm-installed monitoring stack provides the monitoring platform.

`PrometheusRule` resources define application-specific alerting logic.

The relationship is:

    Helm
      ↓
    Prometheus Operator
      ↓
    Prometheus
      ↓
    PrometheusRule
      ↓
    Application-specific Alerts

---

# 7. Autoscaling

## 7.1 Metrics Server Required for HPA

### Problem

The PetClinic Deployment needed CPU-based Horizontal Pod Autoscaling.

### Investigation

A standard CPU-based HPA requires resource metrics from the Kubernetes Metrics API.

Prometheus and Grafana provide monitoring and visualization but do not automatically provide the Metrics API used by a standard CPU-based HPA.

### Solution

Metrics Server was installed:

    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Metrics were verified using:

    kubectl top pods -n petclinic

### Result

The HPA could use CPU metrics to make scaling decisions.

### Lesson Learned

Metrics Server and Prometheus serve different purposes:

    Metrics Server
          ↓
    HPA Resource Metrics

    Prometheus
          ↓
    Monitoring
    Dashboards
    Alerting

This distinction was important when configuring and troubleshooting the PetClinic autoscaling setup.