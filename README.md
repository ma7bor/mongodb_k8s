# MongoDB and Mongo Express on Kubernetes

This project demonstrates how to deploy MongoDB and Mongo Express on a Kubernetes cluster. MongoDB is a NoSQL database, and Mongo Express is a web-based administrative interface for MongoDB.

## Architecture Overview

### Kubernetes Cluster

- **Pod: MongoDB**
  - **Role**: Serves as the NoSQL database server.
  - **Components**:
    - **ConfigMap**: Stores the database name.
    - **Secrets**: Stores the credentials (username and password).
    - **Internal Service**: Facilitates communication between MongoDB and Mongo Express. Acts as a gateway to route traffic to the appropriate MongoDB pod, especially useful when there are multiple replicas.

- **Pod: Mongo Express**
  - **Role**: Provides a UI for visualizing and interacting with the MongoDB database.
  - **Components**:
    - **External Service**: Exposes Mongo Express to the outside world, allowing users to interact with the MongoDB database via the Mongo Express interface.
    - **Internal Communication**: Uses the internal MongoDB service to communicate with the MongoDB pod.

## Prerequisites

- Kubernetes cluster (Minikube is recommended for local development)
- `kubectl` command-line tool installed and configured
- `minikube` command-line tool installed (if using Minikube)

## Setup Instructions

### Step 1: Start Minikube

For Windows:
```bash
minikube start
```

For Linux:
```bash
minikube start --driver=docker
```

### Step 2: Apply Configurations

1. **Create the MongoDB Secret**:

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: mongodb-secret
      namespace: database
    type: Opaque
    data:
      mongo-root-username: dXNlcm5hbWU=
      mongo-root-password: cGFzc3dvcmQ=
    ```

    ```bash
    kubectl apply -f mongodb-secret.yaml
    ```

2. **Create the MongoDB ConfigMap**:

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mongodb-configmap
      namespace: database
    data:
      database-url: mongodb-service
    ```

    ```bash
    kubectl apply -f mongodb-configmap.yaml
    ```

3. **Deploy MongoDB**:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongodb-deployment
      namespace: database
      labels:
        app: mongodb
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: mongodb
      template:
        metadata:
          labels:
            app: mongodb
        spec:
          containers:
          - name: mongodb
            image: mongo
            ports:
            - containerPort: 27017
            env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-password
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: mongodb-service
      namespace: database
    spec:
      selector:
        app: mongodb
      ports:
      - protocol: TCP
        port: 27017
        targetPort: 27017
      type: ClusterIP
    ```

    ```bash
    kubectl apply -f mongodb-deployment.yaml
    ```

4. **Deploy Mongo Express**:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongo-express
      namespace: database
      labels:
        app: mongo-express
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: mongo-express
      template:
        metadata:
          labels:
            app: mongo-express
        spec:
          containers:
          - name: mongo-express
            image: mongo-express
            ports:
            - containerPort: 8081
            env:
            - name: ME_CONFIG_MONGODB_ADMINUSERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-username
            - name: ME_CONFIG_MONGODB_ADMINPASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongo-root-password
            - name: ME_CONFIG_MONGODB_SERVER
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-url
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: mongo-express-service
      namespace: database
    spec:
      selector:
        app: mongo-express
      type: NodePort
      ports:
      - protocol: TCP
        port: 80
        targetPort: 8081
        nodePort: 30000
    ```

    ```bash
    kubectl apply -f mongo-express.yaml
    ```

### Step 3: Access the Services

1. **Run the Mongo Express Service**:
    ```bash
    minikube service mongo-express-service -n database
    ```

    This command will open Mongo Express in your default browser. Use the following credentials to log in:
    - **Username**: `admin`
    - **Password**: `pass`

## Troubleshooting

- **Ensure Minikube is Running**:
  ```bash
  minikube status
  ```

- **Check Pod Status**:
  ```bash
  kubectl get pods -n database
  ```

- **Check Service Status**:
  ```bash
  kubectl get svc -n database
  ```

## Deployment Script

You can use the following deployment script to apply all the configurations at once. Save this script as `deploy.sh` and make it executable.

```bash
#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
  echo "kubectl could not be found. Please install it first."
  exit 1
fi

echo "Deployment is starting..."

# Define the namespace
namespace="database"

# Check if the namespace exists, create it if it doesn't
if ! kubectl get namespace "$namespace" &> /dev/null
then
  echo "Namespace $namespace does not exist. Creating it..."
  kubectl create namespace "$namespace"
  if [ $? -ne 0 ]; then
    echo "Failed to create namespace $namespace"
    exit 1
  fi
else
  echo "Namespace $namespace already exists."
fi

# Define YAML files to be applied
yaml_files=("mongodb-secret.yaml" "mongodb-configmap.yaml" "mongodb-deployment.yaml" "mongo-express.yaml")

# Apply each YAML file in the specified namespace
for file in "${yaml_files[@]}"
do
  if [ -f "$file" ]; then
    echo "Applying $file in namespace $namespace..."
    kubectl apply -f "$file" -n "$namespace"
    if [ $? -ne 0 ]; then
      echo "Failed to apply $file"
      exit 1
    fi
  else
    echo "File $file does not exist"
    exit 1
  fi
done

echo "All specified YAML files have been applied successfully in namespace $namespace."
```

Make the script executable and run it:

```bash
chmod +x deploy.sh
./deploy.sh
```

## Conclusion

By following these steps, you will have a fully functional MongoDB server and Mongo Express UI running on Kubernetes. This setup allows you to interact with MongoDB through a user-friendly web interface, making database management easier.