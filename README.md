from a new cluster to install kafka:


- Install Argo
```
kubectl create namespace argocd                                                                    
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
- Expose Argo

```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

- Get Argo password

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

at this point you can log in using admin username and password above


run helm against repo:

```
kubectl create namespace confluent
kubectl config set-context --current --namespace confluent
helm repo add confluentinc https://packages.confluent.io/helm  in confluent                                 
helm repo update -n confluent
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes -n confluent
```

create Argo application:

kubectl apply -f kafka-application.yaml

Once everything is running:

kubeclt get svc -n confluent

kubectl patch svc controlcenter-0-internal -p '{"spec": {"type": "LoadBalancer"}}'


`kubeclt get svc -n confluent` again to get the ip then <ip>:9021 to get control center dash

# CI/CD Process for Continuous Integration and Deployment

## Folder Structure

```
.
├── charts/
│   ├── hallo-world/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── ingress.yaml
│   │   │   └── _helpers.tpl
│   ├── web/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── ingress.yaml
│   │   │   └── _helpers.tpl
│   └── argocd-snowplow/
│       └── charts/
│           └── hallo-world-application.yaml
├── hallo-world/
│   ├── src/
│   ├── Dockerfile
│   └── README.md
└── web/
    ├── index.html
    └── Dockerfile
```

## CI/CD Automation Process

### Continuous Integration (CI)

1. **Developer Workflow:**
   - **Code Changes:** Developers make changes to the source code in the `hallo-world/` directory.
   - **Version Control:** Changes are committed and pushed to the GitHub repository.
   - **GitHub Actions:**
     - **Trigger Build:** A GitHub Action workflow triggers a new build when changes are pushed.
     - **Run Tests:** The workflow runs tests to ensure the code changes do not break the application.
     - **Build Docker Image:** If tests pass, the workflow builds a new Docker image and pushes it to Docker Hub.
     - **Update Helm Chart:** The Docker image tag in the `values.yaml` file of the `hallo-world/` Helm chart is updated with the new image tag.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    paths:
      - 'hallo-world/**'
      - '!charts/**'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v2

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    - name: Login to DockerHub
      uses: docker/login-action@v1
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build and Push Docker Image
      run: |
        docker build -t socrates12345/hallo-world:${{ github.sha }} .
        docker push socrates12345/hallo-world:${{ github.sha }}

    - name: Update Helm Chart
      run: |
        sed -i 's/tag: .*/tag: ${{ github.sha }}/' charts/hallo-world/values.yaml

    - name: Commit Helm Chart Changes
      run: |
        git config --global user.email "you@example.com"
        git config --global user.name "Your Name"
        git add charts/hallo-world/values.yaml
        git commit -m "Update hallo-world image tag to ${{ github.sha }}"
        git push
```

### Continuous Deployment (CD)

2. **DevOps Workflow:**
   - **Helm Chart Changes:** DevOps engineers make changes to the Helm chart configurations in the `charts/` directory.
   - **Version Control:** Changes are committed and pushed to the GitHub repository.
   - **ArgoCD:**
     - **Sync Application:** ArgoCD monitors the repository for changes to the Helm charts.
     - **Deploy Changes:** When changes are detected, ArgoCD syncs the changes and deploys them to the Kubernetes cluster.

```yaml
# .github/workflows/cd.yml
name: CD

on:
  push:
    paths:
      - 'charts/**'
      - '!hallo-world/**'

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v2

    - name: Deploy to ArgoCD
      env:
        KUBECONFIG: ${{ secrets.KUBECONFIG }}
      run: |
        kubectl apply -f charts/argocd-snowplow/charts/hallo-world-application.yaml
```

## Tools and Their Functions

- **GitHub Actions:** Automates CI/CD workflows, triggering builds, tests, and deployments.
- **Jenkins:** An alternative CI/CD server that automates parts of the software development process.
- **GitLab CI:** CI/CD tool integrated with GitLab to automate the lifecycle of applications.
- **ArgoCD:** Declarative GitOps continuous delivery tool for Kubernetes, synchronizing application state with Git repositories.
- **Helm:** Kubernetes package manager that deploys applications and services using charts.
- **Kubernetes:** Orchestrates the deployment, scaling, and operations of containerized applications.
- **Docker:** Packages applications into containers for consistent development and deployment environments.
- **Docker Hub:** Repository for storing and sharing Docker images.
- **Prometheus:** Collects and monitors metrics from applications.
- **Grafana:** Visualizes metrics and logs collected from various sources.
- **Kafka:** Streams platform for building real-time data pipelines and applications.
- **Terraform:** Manages infrastructure as code for automated provisioning and management.
- **SonarQube:** Analyzes code for quality and security issues.
- **Vault:** Manages and protects sensitive information and secrets.

By integrating these tools, the CI/CD process is streamlined, ensuring efficient and reliable code integration, testing, deployment, and monitoring. This automation enables continuous delivery and deployment of high-quality software.

# Workflow for Creating a New Application `hallo-world`

This guide provides a step-by-step workflow for creating and integrating a new application called `hallo-world` into your existing setup with the `argocd-snowplow/chart` folder and the `repo factory`.

## Folder Structure

```bash
argocd-snowplow/
  ├── chart/
  │   ├── hallo-world/
  │   │   ├── charts/
  │   │   ├── templates/
  │   │   │   ├── deployment.yaml
  │   │   │   ├── ingress.yaml
  │   │   │   ├── service.yaml
  │   │   │   └── _helpers.tpl
  │   │   ├── Chart.yaml
  │   │   ├── values.yaml
  ├── hallo-world-application.yaml
  ├── charts-application.yaml
```

## Step 1: Create the `hallo-world` Application Directory

Navigate to the `charts` directory and create a new Helm chart for the `hallo-world` application.

```sh
cd charts
helm create hallo-world
```

## Step 2: Customize the `hallo-world` Helm Chart

Modify the files in the `hallo-world` directory as needed.

### Chart.yaml

Update the chart metadata.

```yaml
apiVersion: v2
name: hallo-world
description: A Helm chart for the Hallo World application
version: 0.1.0
appVersion: "1.0"
```

### values.yaml

Define the default configuration values.

```yaml
replicaCount: 1

image:
  repository: socrates12345/hallo-world
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  annotations: {}
  hosts:
    - host: hallo-world.local
      paths:
        - path: /
          pathType: Prefix
          port: 8080
  tls: []
```

### templates/deployment.yaml

Update the deployment template.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "hallo-world.fullname" . }}
  labels:
    {{- include "hallo-world.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "hallo-world.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "hallo-world.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.service.port }}
```

### templates/service.yaml

Update the service template.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hallo-world.fullname" . }}
  labels:
    {{- include "hallo-world.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
  selector:
    {{- include "hallo-world.selectorLabels" . | nindent 4 }}
```

### templates/ingress.yaml

Create an ingress template.

```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "hallo-world.fullname" . }}
  annotations:
    {{- range $key, $value := .Values.ingress.annotations }}
      {{ $key }}: {{ $value | quote }}
    {{- end }}
spec:
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "hallo-world.fullname" $ }}
                port:
                  number: {{ .port }}
          {{- end }}
    {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
{{- end }}
```

### templates/_helpers.tpl

Define helper templates.

```yaml
{{- define "hallo-world.labels" -}}
app.kubernetes.io/name: {{ include "hallo-world.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "hallo-world.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hallo-world.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "hallo-world.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "hallo-world.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}
```

## Step 3: Build and Push the Docker Image

Create the `hallo-world` application, build the Docker image, and push it to your DockerHub repository.

### Dockerfile

Create a `Dockerfile` for your application in the `hallo-world` directory.

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
```

### Build and Push Commands

```sh
docker build -t socrates12345/hallo-world:latest hallo-world/
docker push socrates12345/hallo-world:latest
```

## Step 4: Create ArgoCD Application for `hallo-world`

Add an ArgoCD application manifest to manage the deployment of the `hallo-world` application.

### hallo-world-application.yaml

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hallo-world
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/socrates-kubefirst/argo-gitops.git'
    targetRevision: HEAD
    path: charts/hallo-world
    directory:
      recurse: true
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: hallo-world
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Step 5: Update the Main ArgoCD Application

Update the main ArgoCD application to include the new `hallo-world` application.

### charts-application.yaml

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: charts
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/socrates-kubefirst/argo-gitops.git'
    targetRevision: HEAD
    path: charts
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Step 6: Commit and Push Changes

Commit and push your changes to the Git repository.

```sh
git add .
git commit -m "Add hallo-world application"
git push origin main
```

## Step 7: Apply ArgoCD Application

Apply the new ArgoCD application to create the `hallo-world` application in ArgoCD.

```sh
kubectl apply -f argocd-snowplow/charts-application.yaml
```

This workflow will set up the new `hallo-world` application in your existing ArgoCD setup, including building and deploying the Docker image, configuring Helm charts, and managing deployment with ArgoCD.


Yes, that is correct. There will be two separate folders for the `hallo-world` application:

1. **Source Code Folder:** This folder contains the application's source code and is managed by the developers.
2. **Helm Charts Folder:** This folder contains the Helm charts for deploying the application to Kubernetes and is managed by the DevOps engineers.

## Directory Structure

The directory structure will look something like this:

```
.
├── charts
│   ├── hallo-world
│   │   ├── Chart.yaml
│   │   ├── templates
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── ingress.yaml
│   │   │   └── _helpers.tpl
│   │   └── values.yaml
│   └── other-charts
├── hallo-world
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── other-source-files
└── README.md
```

## Developer's Perspective

### Modifying the Source Code

1. **Navigate to the Source Code Directory:**

    ```sh
    cd hallo-world
    ```

2. **Make the necessary code changes:**
   
    Edit the application files, such as `app.py`, `requirements.txt`, etc., to implement the desired features or fixes.

3. **Update Dependencies:**

    If you added new dependencies, update the `requirements.txt` file.

    ```sh
    pip freeze > requirements.txt
    ```

4. **Build and Test Locally:**

    ```sh
    docker build -t socrates12345/hallo-world:latest .
    docker run -p 8080:8080 socrates12345/hallo-world:latest
    ```

5. **Push Changes to Repository:**

    ```sh
    git add .
    git commit -m "Describe the changes made"
    git push origin main
    ```

## DevOps Engineer's Perspective

### Updating and Deploying the Helm Chart

1. **Navigate to the Helm Charts Directory:**

    ```sh
    cd charts/hallo-world
    ```

2. **Build and Push Docker Image:**

    ```sh
    docker build -t socrates12345/hallo-world:latest ../../hallo-world/
    docker push socrates12345/hallo-world:latest
    ```

3. **Update Helm Chart:**

    Edit `values.yaml` and other necessary Helm chart files:

    ```yaml
    image:
      repository: socrates12345/hallo-world
      tag: "latest"
    ```

4. **Commit and Push Helm Chart Changes:**

    ```sh
    git add .
    git commit -m "Update hallo-world Helm chart for new changes"
    git push origin main
    ```

5. **Sync Changes in ArgoCD:**

    Log in to the ArgoCD dashboard and sync the `hallo-world` application to deploy the changes.

    Alternatively, use the CLI:

    ```sh
    argocd app sync hallo-world
    ```

## Summary

- **Developer:** Modify the source code, test changes locally, and push to the repository.
- **DevOps Engineer:** Build and push the Docker image, update Helm charts, and deploy changes using ArgoCD.

Following these steps ensures that changes to the `hallo-world` application are smoothly integrated and deployed in your Kubernetes environment.


Automating the process of continuous integration (CI) and continuous deployment (CD) involves setting up pipelines that automate the steps required to build, test, and deploy your application. Here’s how you can achieve this for the `hallo-world` application using popular CI/CD tools like GitHub Actions, Jenkins, or GitLab CI, in conjunction with Docker and ArgoCD.

## Continuous Integration (CI)

### GitHub Actions

1. **Create a `.github/workflows/ci.yml` file in your repository:**

    ```yaml
    name: CI

    on:
      push:
        branches:
          - main
      pull_request:
        branches:
          - main

    jobs:
      build:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout code
            uses: actions/checkout@v2

          - name: Set up Python
            uses: actions/setup-python@v2
            with:
              python-version: '3.x'

          - name: Install dependencies
            run: |
              python -m pip install --upgrade pip
              pip install -r hallo-world/requirements.txt

          - name: Test with pytest
            run: |
              cd hallo-world
              pytest

          - name: Build Docker image
            run: |
              docker build -t socrates12345/hallo-world:latest hallo-world/
            env:
              DOCKER_BUILDKIT: 1

          - name: Log in to Docker Hub
            run: echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin

          - name: Push Docker image
            run: docker push socrates12345/hallo-world:latest
    ```

### Jenkins

1. **Create a `Jenkinsfile` in your repository:**

    ```groovy
    pipeline {
        agent any

        environment {
            DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        }

        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }

            stage('Build') {
                steps {
                    script {
                        docker.build("socrates12345/hallo-world:latest", "hallo-world/")
                    }
                }
            }

            stage('Test') {
                steps {
                    sh 'cd hallo-world && pytest'
                }
            }

            stage('Push') {
                steps {
                    script {
                        docker.withRegistry('https://index.docker.io/v1/', 'DOCKER_HUB_CREDENTIALS') {
                            docker.image("socrates12345/hallo-world:latest").push()
                        }
                    }
                }
            }
        }
    }
    ```

### GitLab CI

1. **Create a `.gitlab-ci.yml` file in your repository:**

    ```yaml
    stages:
      - build
      - test
      - push

    build:
      stage: build
      script:
        - docker build -t socrates12345/hallo-world:latest hallo-world/

    test:
      stage: test
      script:
        - pip install -r hallo-world/requirements.txt
        - cd hallo-world && pytest

    push:
      stage: push
      script:
        - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD"
        - docker push socrates12345/hallo-world:latest
    ```

## Continuous Deployment (CD)

### ArgoCD

1. **Create an ArgoCD application for the `hallo-world` Helm chart:**

    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: hallo-world
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: 'https://github.com/your-repo.git'
        targetRevision: HEAD
        path: charts/hallo-world
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: hallo-world
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
    ```

2. **Configure GitHub Actions to trigger ArgoCD sync:**

    Add the following step to your GitHub Actions workflow after pushing the Docker image:

    ```yaml
    - name: Sync ArgoCD application
      run: |
        argocd app sync hallo-world
      env:
        ARGOCD_SERVER: ${{ secrets.ARGOCD_SERVER }}
        ARGOCD_USERNAME: ${{ secrets.ARGOCD_USERNAME }}
        ARGOCD_PASSWORD: ${{ secrets.ARGOCD_PASSWORD }}
    ```

3. **Configure Jenkins to trigger ArgoCD sync:**

    Add the following stage to your `Jenkinsfile`:

    ```groovy
    stage('Deploy') {
        steps {
            sh '''
                argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure
                argocd app sync hallo-world
            '''
        }
    }
    ```

4. **Configure GitLab CI to trigger ArgoCD sync:**

    Add the following job to your `.gitlab-ci.yml`:

    ```yaml
    deploy:
      stage: deploy
      script:
        - argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure
        - argocd app sync hallo-world
    ```

## Summary

By integrating CI/CD pipelines with GitHub Actions, Jenkins, or GitLab CI, along with ArgoCD for automated deployment, you can ensure a smooth and automated process for building, testing, and deploying your applications. Developers focus on the source code, while DevOps engineers manage the Helm charts and deployment configurations.