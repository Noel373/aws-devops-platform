# AWS DevOps CI/CD Platform – Spring PetClinic

> **End-to-end DevOps project demonstrating CI/CD, AWS, Kubernetes, Infrastructure as Code, container security, monitoring, autoscaling, and production-oriented deployment practices.**

![AWS](https://img.shields.io/badge/AWS-Cloud-orange)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-blue)
![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-purple)
![Jenkins](https://img.shields.io/badge/CI%2FCD-Jenkins-red)
![Docker](https://img.shields.io/badge/Containers-Docker-blue)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-orange)
![Grafana](https://img.shields.io/badge/Dashboards-Grafana-orange)
---

##  Project Overview

This project demonstrates a complete DevOps workflow for deploying the **Spring PetClinic** application to AWS.

The objective was not simply to deploy an application, but to build a practical DevOps platform covering the lifecycle from source code commit to a running, monitored and scalable application on Kubernetes.

The project includes:

- Automated CI/CD with Jenkins
- Infrastructure provisioning with Terraform
- AWS EKS Kubernetes cluster
- Amazon ECR container registry
- Amazon RDS PostgreSQL
- AWS Application Load Balancer
- Kubernetes deployment and service management
- Container and dependency vulnerability scanning
- Prometheus and Grafana monitoring
- Kubernetes alerting
- Horizontal Pod Autoscaling
- Secure network design
- Namespace-scoped Kubernetes permissions

---

# Architecture

                         ┌─────────────────────┐
                         │      Developer      │
                         │                     │
                         │   Git Push / PR     │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       GitHub        │
                         │   Source Control    │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │      Jenkins        │
                         │                     │
                         │  CI/CD Pipeline     │
                         └──────────┬──────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
             Maven Build       SonarQube          Trivy Scan
             & Tests           Analysis           Dependencies
                 │                                     │
                 └──────────────────┬──────────────────┘
                                    │
                                    ▼
                            ┌─────────────────┐
                            │  Docker Build   │
                            └────────┬────────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │    Trivy    │
                              │ Image Scan  │
                              └──────┬──────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │     ECR     │
                              │  Container  │
                              │   Registry  │
                              └──────┬──────┘
                                     │
                                     ▼
                         ┌──────────────────────┐
                         │       AWS EKS        │
                         │                      │
                         │   Kubernetes Cluster  │
                         └──────────┬───────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
          ┌─────────────┐    ┌─────────────┐   ┌─────────────┐
          │ PetClinic   │    │ Prometheus  │   │   Grafana   │
          │ Deployment  │    │             │   │             │
          └──────┬──────┘    └─────────────┘   └─────────────┘
                 │
                 ▼
        ┌─────────────────────┐
        │ AWS Load Balancer   │
        │      ALB            │
        └──────────┬──────────┘
                   │
                   ▼
                Internet

                   │
                   ▼
        ┌─────────────────────┐
        │    Amazon RDS       │
        │    PostgreSQL       │
        │                     │
        │    Private Subnet   │
        └─────────────────────┘