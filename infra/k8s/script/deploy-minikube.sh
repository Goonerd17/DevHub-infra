#!/bin/bash
set -e

DOCKERHUB_ID=goonerd

# ===============================
# 1️⃣ Minikube 시작
# ===============================
echo "Starting Minikube..."
minikube start

# ===============================
# 1-1️⃣ Ingress Controller 활성화
# ===============================
echo "Enabling Ingress Controller..."
minikube addons enable ingress

# 상태 확인
echo "Checking Ingress Controller pods..."
kubectl get pods -n ingress-nginx

# ===============================
# 2️⃣ Docker Hub에 이미지 빌드 및 푸시
# ===============================
echo "Building and pushing backend..."
cd /c/DevHub-backend
docker build -t devhub-backend:latest .
docker tag devhub-backend:latest $DOCKERHUB_ID/devhub-backend:latest
docker push $DOCKERHUB_ID/devhub-backend:latest

echo "Building and pushing frontend..."
cd /c/DevHub-frontend
docker build -t devhub-frontend:latest .
docker tag devhub-frontend:latest $DOCKERHUB_ID/devhub-frontend:latest
docker push $DOCKERHUB_ID/devhub-frontend:latest

# ===============================
# 3️⃣ K8s 리소스 적용
# ===============================
cd /c/DevHub-infra/infra/k8s

echo "Applying DevHub-backend resources..."
kubectl apply -f devhub-backend/namespace.yml
kubectl apply -f devhub-backend/deployment.yml
kubectl apply -f devhub-backend/service.yml

echo "Applying DevHub-frontend resources..."
kubectl apply -f devhub-frontend/namespace.yml
kubectl apply -f devhub-frontend/deployment.yml
kubectl apply -f devhub-frontend/service.yml

echo "Applying DevHub Ingress..."
kubectl apply -f ingress/devhub-ingress.yml

# ===============================
# 4️⃣ 배포 상태 확인
# ===============================
sleep 5

echo "Backend Pods:"
kubectl get pods -n devhub-backend

echo "Frontend Pods:"
kubectl get pods -n devhub-frontend

echo "Services:"
kubectl get svc -n devhub-backend
kubectl get svc -n devhub-frontend

echo "Ingress:"
kubectl get ingress -n devhub-frontend

echo "✅ Deployment complete!"
echo "Use 'http://devhub.local' in your browser (ensure /etc/hosts is mapped to your Minikube IP) to open the frontend."
