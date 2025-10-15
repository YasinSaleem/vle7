# MyApp - Simple Express App

A simple Node.js Express application for demonstrating blue-green deployments with Kubernetes.

## Features

- Displays app version from package.json
- Shows deployment color (blue/green)
- Displays BUILD_NUMBER environment variable
- Health check endpoint
- Responsive web interface
.
## Local Development

### Prerequisites
- Node.js 18+
- Docker (optional)

### Run Locally
```bash
# Install dependencies
npm install

# Start the application
npm start

# With environment variables
COLOR=green BUILD_NUMBER=123 npm start
```

Visit: http://localhost:8080

## Docker

### Build Image
```bash
docker build -t myapp:latest .
```

### Run Container
```bash
# Blue deployment
docker run -p 8080:8080 -e COLOR=blue -e BUILD_NUMBER=1 myapp:latest

# Green deployment  
docker run -p 8080:8080 -e COLOR=green -e BUILD_NUMBER=2 myapp:latest
```

### Push to Registry
```bash
# Tag for registry
docker tag myapp:latest your-registry/myapp:v1.0.0

# Push to registry
docker push your-registry/myapp:v1.0.0
```

## Kubernetes Deployment

### Deploy Blue Version
```bash
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/service.yaml
```

### Deploy Green Version (Blue-Green)
```bash
# Deploy green version
kubectl apply -f k8s/deployment-green.yaml

# Switch traffic to green
kubectl patch service myapp-service -p '{"spec":{"selector":{"color":"green"}}}'

# Cleanup old blue deployment
kubectl delete -f k8s/deployment-blue.yaml
```

### Using Kustomization
```bash
# Apply all resources
kubectl apply -k k8s/

# Switch to green overlay (if implemented)
kubectl apply -k k8s/overlays/green/
```

## Endpoints

- `GET /` - Main application page
- `GET /health` - Health check endpoint (JSON)

## Environment Variables

- `COLOR` - Deployment color (blue/green, default: blue)
- `BUILD_NUMBER` - Build number (default: dev)
- `PORT` - Server port (default: 8080)

## CI/CD Integration

This app is designed to work with Jenkins pipelines for automated blue-green deployments:

1. Build Docker image with BUILD_NUMBER
2. Deploy to Kubernetes cluster
3. Run health checks
4. Switch traffic between blue/green deployments