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
yaml_files=("mongo-secret.yaml" "mongo.yaml" "mongo-configmap.yaml" "mongo-express.yaml")

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