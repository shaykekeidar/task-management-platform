# Task Management Platform

Cloud-native application platform demonstrating:

- React frontend
- Node.js microservices
- PostgreSQL
- Docker containerization
- Kubernetes deployments and services
- Stateful workloads with PostgreSQL
- Persistent storage
- ConfigMaps and Secrets
- Resource requests and limits
- ResourceQuota and LimitRange guardrails
- Horizontal Pod Autoscaling (HPA)
- Pod Disruption Budgets (PDB)
- Kubernetes RBAC and ServiceAccounts
- NetworkPolicy
- Ingress and TLS
- Helm packaging and environment-specific values
- Argo CD
- GitOps-based continuous delivery
- Prometheus and Grafana monitoring
- Loki-based centralized logging

## OpenShift and CloudNativePG POC

The repository also includes hands-on OpenShift experiments.

### Implemented components

- OpenShift application migration and deployment
- ImageStream experiments
- OpenShift Routes
- CloudNativePG Operator installation
- PostgreSQL cluster provisioning through a custom resource
- Operator reconciliation testing

### CloudNativePG validation

The PostgreSQL Pod was manually deleted to verify the
Operator's reconciliation behavior.

The Operator recreated the Pod, which subsequently
returned to the Running and Ready state.

This exercise demonstrates Kubernetes Operator-based
workload reconciliation.

Note: Pod recreation does not independently verify
database persistence, backup, or disaster recovery.
