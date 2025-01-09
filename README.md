# ATC Webapp Project

## Overview
This project demonstrates a complete cloud-native application deployment using AWS EKS (Elastic Kubernetes Service). It consists of a simple static webpage served through an Nginx container, deployed on a Kubernetes cluster provisioned with Terraform.

## Architecture
- **Infrastructure**: AWS EKS Cluster with managed node groups
- **Application**: Static webpage served via Nginx
- **Deployment**: Kubernetes-based deployment with LoadBalancer service
- **Infrastructure as Code**: Terraform
- **Container Registry**: Docker Hub (image: aiazmohammed/atc-test:4)
- **Monitoring**: Prometheus

## Prerequisites
- AWS CLI configured
- Terraform installed
- kubectl installed
- Docker installed (for building images)
- Helm installed

## Project Structure
```
.
├── Dockerfile
├── static-content/
│   └── index.html
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── aws-auth-cm.yaml
└── terraform/
    ├── eks.tf
    └── provider.tf
```

## Infrastructure Setup

### Terraform Configuration
The infrastructure is defined using Terraform with the following main components:

1. **EKS Cluster**:
   - Cluster Version: 1.31
   - Region: us-east-1
   - VPC and Subnet configuration included
   - Public endpoint access enabled

2. **Node Groups**:
   - Instance Type: t2.small
   - OS: Amazon Linux 2023
   - Min/Max Size: 3/10 nodes
   - Desired Size: 3 nodes

3. **Security Groups**:
   - Node group security group with public access
   - All inbound/outbound traffic allowed (Note: This is for testing purposes only)

### Deployment

1. **Initialize and Apply Terraform**:
```bash
terraform init
terraform apply
```
Note: if you see the nodes in 'Not ready' state, add the 'vpn-cni' add-on manually and re-apply the 'terraform apply'.

2. **Update kubeconfig**:
```bash
aws eks update-kubeconfig --name ats-cluster --region us-east-1
```

## Application Components

### Docker Image
The application uses a simple Nginx-based Docker image:
```dockerfile
FROM nginx:alpine
COPY static-content /usr/share/nginx/html
EXPOSE 80
```

### Kubernetes Resources

1. **Deployment**:
   - 1 replica of the webapp
   - Using image: aiazmohammed/atc-test:4
   - Exposed port: 80

2. **Service**:
   - Type: LoadBalancer
   - Port: 80
   - Target Port: 80

3. **ConfigMaps**:
   - aws-auth: For AWS IAM integration
   - prometheus-config: For monitoring setup

### Access Control
The cluster uses AWS IAM for authentication with the following roles:
- Node group role for EC2 instances
- Root user access
- Terraform CLI user access

## Deployment Instructions

1. **Deploy Kubernetes Resources**:
```bash
kubectl apply -f kubernetes/aws-auth-cm.yaml 
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
```

Note: In the aws-auth-cm.yaml file replace the role with one generated one via terraform

2. **Verify Deployment**:
```bash
kubectl get pods
kubectl get services
```

3. **Access Application**:
The application will be accessible through the LoadBalancer URL:
```bash
kubectl get service webapp-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Monitoring Setup

### Prometheus Installation and Configuration

1. **Create Monitoring Namespace**:
```bash
kubectl create ns monitoring
```

2. **Add Prometheus Helm Repository**:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

3. **Install Prometheus using Helm**:
```bash
helm install prometheus prometheus-community/prometheus -n monitoring
```

4. **Access Prometheus Dashboard**:
```bash
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```
After running the port-forward command, access the Prometheus dashboard at: http://localhost:9090

### Monitoring Components
The Prometheus installation includes:
- Prometheus Server: Main time-series database and monitoring system
- Alert Manager: Handles alerts
- Node Exporter: Collects hardware and OS metrics
- Kube State Metrics: Generates metrics about Kubernetes objects

### Prometheus Dashboard Features
- Query Interface: Use PromQL to query metrics
- Graphs & Visualizations: View metric data over time
- Alerts: Configure and view alerting rules
- Targets: Monitor scrape targets and their health
- Service Discovery: View automatically discovered services

## Security Considerations
- The current security group configuration allows all traffic (0.0.0.0/0) and should be restricted in production
- IAM roles and permissions should be reviewed and limited based on the principle of least privilege
- Consider implementing network policies in Kubernetes
- Enable encryption at rest for sensitive data
- Secure Prometheus access using authentication and authorization

## Monitoring and Maintenance
- The cluster includes core addons:
  - vpc-cni
  - coredns
  - kube-proxy
  - aws-ebs-csi-driver
- Prometheus monitoring is configured for:
  - Node-level metrics
  - Pod metrics
  - Service metrics
  - Cluster state metrics
- Use AWS CloudWatch for logging and monitoring

## Best Practices
1. Regularly update EKS version and node AMIs
2. Implement proper resource requests and limits
3. Use namespace isolation for different environments
4. Implement proper backup and disaster recovery procedures
5. Monitor cluster and application metrics
6. Implement proper CI/CD pipelines for deployments
7. Set up alerting rules in Prometheus for critical metrics
8. Regularly backup Prometheus data
9. Configure appropriate retention periods for metrics

## Troubleshooting
### Common Prometheus Issues
1. Port-forward not working:
   - Verify the prometheus-server pod is running
   - Check for any network policies blocking access
   - Ensure the service name and namespace are correct

2. No metrics showing up:
   - Verify service discovery is working
   - Check if pods have proper annotations for scraping
   - Validate network connectivity between Prometheus and targets
