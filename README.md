# Prometheus Metrics Configuration

## Table of contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Terraform](#terraform)
* [Helm](#helm)
* [Notes](#notes)

## Introduction

The following project consists of one Kube Prometheus Stack installation in Azure Kubernetes Service.

The project shows different approaches for sending metrics to Prometheus.

## Requirements

- Docker Desktop (local environment)
- Kubernetes feature active in Docker Desktop
- Azure CLI
- Terraform
- Kubectl
- Helm Chart

## Terraform

### Configuration

Assign the RBAC role "Contributor" to the User account on the Subscription level.

Create the file `terraform.tfvars` with the values for the following Terraform variables:

```sh
location="<location>"
location_abbreviation="<location_abbeviation>"
environment="<environment>"
workload_name="<workload_name>"
allowed_public_ip_address_ranges=<ip_address_ranges>
allowed_public_ip_addresses=<ip_addressses>
```

### Terraform Project Initialization

```sh
terraform init -reconfigure
```

### Verify the Updates in the Terraform Code

```sh
terraform plan
```

### Apply the Updates from the Terraform Code

```sh
terraform apply -auto-approve
```

### Format Terraform Code

```sh
find . -not -path "*/.terraform/*" -type f -name '*.tf' -print | uniq | xargs -n1 terraform fmt
```

## Helm

### Deployment Prometheus

```sh
cd helm
kubectl create namespace metrics
helm dependency build
helm install --namespace metrics -f values.yaml metrics .
```

### Upgrade Prometheus

```sh
helm upgrade -f values.yaml --namespace metrics metrics .
```

### Cleanup Prometheus

```sh
helm uninstall metrics --namespace metrics
```

### Check the deployments

```sh
kubectl get all,cm,secret,ing -n metrics
```

### Access Prometheus

```sh
kubectl --namespace metrics port-forward services/prometheus-operated 9090
```

### Configuration in Grafana

Add a Source of type "Prometheus" with the following configuration:

http://prometheus-server.metrics.svc.cluster.local

## Notes

1. ServiceMonitor

Verify the labels applied to the Prometheus configuration:

```sh
kubectl describe prometheus/metrics-kube-prometheus-st-prometheus -n metrics 
```

The Prometheus Operator is configured with:

```sh
Service Monitor Selector:
    Match Labels:
      Release:  metrics
```

Grafana Tempo is configured with:

```sh
tempo:
  serviceMonitor:
    enabled: true
    interval: 15s
    additionalLabels:
      release: metrics
    annotations: {}
```

2. Additional Scrape Configs

Prometheus is configured with additional scrape configurations:

```sh
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalScrapeConfigs:
        - job_name: 'grafana-tempo-additional'
          scrape_interval: 15s
          static_configs:
            - targets: ['grafana-tempo.metrics.svc.cluster.local:3100']
          relabel_configs:
            - target_label: 'cluster'
              replacement: 'aks'
              action: 'replace'
```

3. ScrapeConfig

Prometheus configuration:

```sh
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      scrapeConfigSelector:
        matchLabels:
          prometheus: monitoring-prometheus
```

The following are the parameters to the ScrapeConfig resource:

```sh
global:
  scrapeconfig:
    name: "grafana-tempo"
    labels:
      prometheus: monitoring-prometheus
    spec:
      staticConfigs:
        - targets: ['grafana-tempo.metrics.svc.cluster.local:3100']
      relabelings:
        - targetLabel: 'cluster'
          replacement: 'aks'
          action: 'replace'
```
