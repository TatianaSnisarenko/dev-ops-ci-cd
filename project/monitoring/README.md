# Monitoring Checklist (Prometheus + Grafana on EKS)

This document describes how to install and verify monitoring components (Prometheus and Grafana) on the existing EKS cluster created by Terraform.

## ✅ Prerequisites

Before installing monitoring, make sure that:

- EKS cluster is up and running.
- `aws eks update-kubeconfig` was executed and `kubectl` points to the correct cluster.
- Terraform infrastructure has been successfully applied:
  - VPC
  - EKS
  - RDS
  - ECR
  - Jenkins
  - Argo CD

Quick check:

```bash
kubectl get nodes
kubectl get ns
```

You should see at least one node and namespaces like default, kube-system, jenkins, argocd.

## 1. Create monitoring namespace

```bash
kubectl create namespace monitoring
```

Verify:

```bash
kubectl get ns
```

**monitoring should be in the list**

## 2. Install Prometheus via Helm

Add the Prometheus community Helm repo:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Install Prometheus into the monitoring namespace:

```bash
helm install prometheus prometheus-community/prometheus --namespace monitoring
```

Verify that Prometheus components are running:

```bash
kubectl get pods -n monitoring
```

You should see pods with names like:

```bash
prometheus-server-...

prometheus-alertmanager-...

prometheus-kube-state-metrics-...

prometheus-node-exporter-...
```

## 3. Install Grafana via Helm

Add Grafana Helm repo (if not already added):

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install Grafana in the monitoring namespace with a known admin password:

```bash
helm install grafana grafana/grafana --namespace monitoring --set adminPassword=admin123
```

⚠️ In real environments you should use a strong, unique password and secrets management.
For this lab, admin123 is enough to simplify evaluation.

Verify that Grafana pod is running:

```bash
kubectl get pods -n monitoring
```

You should see something like:

```
grafana-xxxxxx-xxxxx in Running state.
```

4. Port-forward Grafana

To access Grafana from your local machine:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Now open in browser:

http://localhost:3000

**Login:**

Username: admin
Password: admin123

## 5. Connect Prometheus as a Data Source in Grafana

**In Grafana UI:**

- Go to Configuration → Data sources.
- Click "Add data source".
- Select Prometheus.

In the URL field, enter the in-cluster service name:

http://prometheus-server.monitoring.svc:80

Click "Save & test".

You should see a green message like **"Data source is working"**.

## 6. Import a Dashboard

Go to Dashboards → Import.

Choose any popular Prometheus/Kubernetes dashboard, for example:

ID 315 (Prometheus 2.0 Stats) or any official "Node Exporter Full" dashboard

Click Load, then select the Prometheus data source you just configured.

Click Import.

You should now see real-time metrics from your cluster.

## 7. Basic Validation

Use the following commands to ensure monitoring components are present:

```bash
kubectl get all -n monitoring
```

You should see:

```bash
svc/prometheus-server
svc/grafana
multiple pods for Prometheus and Grafana
```

Additionally, confirm in Grafana:

Prometheus data source is green (working).

At least one dashboard is showing metrics (CPU, memory, requests, etc).

## 8. Cleanup (optional for local re-runs)

If you need to remove monitoring components without destroying the entire infrastructure:

```bash
helm uninstall grafana -n monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```
