
# Task Management Platform

A hands-on Kubernetes and OpenShift platform for deploying and operating a containerized task management application.

The project demonstrates microservices deployment, persistent storage, GitOps, observability, networking, and Kubernetes security through practical infrastructure exercises.

## Technology Stack

### Application
- React frontend
- Node.js microservices
- PostgreSQL database
- Docker containerization

### Kubernetes Infrastructure
- Deployments, Services, and Stateful workloads
- Persistent storage
- ConfigMaps and Secrets
- Resource requests and limits
- ResourceQuota and LimitRange
- Horizontal Pod Autoscaling (HPA)
- Pod Disruption Budgets (PDB)
- Kubernetes RBAC and ServiceAccounts
- NetworkPolicy
- Ingress and TLS

### Deployment and GitOps
- Helm packaging and environment-specific values
- Argo CD
- GitOps-based continuous delivery

### Observability
- Prometheus and Grafana monitoring
- Loki-based centralized logging

## OpenShift and CloudNativePG POC

The repository also includes hands-on OpenShift experiments.

### Implemented Components
- OpenShift application migration and deployment
- ImageStream experiments
- OpenShift Routes
- CloudNativePG Operator installation
- PostgreSQL cluster provisioning through a custom resource
- Operator reconciliation testing

### CloudNativePG Validation

The PostgreSQL Pod was manually deleted to verify the Operator's reconciliation behavior.

The Operator recreated the Pod, which subsequently returned to the Running and Ready state.

This exercise demonstrates Kubernetes Operator-based workload reconciliation.

**Note:** Pod recreation does not independently verify database persistence, backup, or disaster recovery.

## Project Status

This is an evolving hands-on Kubernetes and OpenShift engineering project.

The repository contains practical exercises covering application deployment, GitOps, observability, networking, security, and operator-managed workloads.

The environment is intended for learning, experimentation, and technical demonstrations rather than production deployment.
