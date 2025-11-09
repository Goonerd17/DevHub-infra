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
cd /c/DevHub-Frontend
docker build -t devhub-frontend:latest .
docker tag devhub-frontend:latest $DOCKERHUB_ID/devhub-frontend:latest
docker push $DOCKERHUB_ID/devhub-frontend:latest

# ===============================
# 3️⃣ K8s 리소스 적용 (통합 네임스페이스)
# ===============================
cd /c/DevHub-infra/infra/k8s

echo "Applying DevHub namespace..."
kubectl apply -f devhub-frontend/namespace.yml

echo "Applying Backend resources..."
kubectl apply -f devhub-backend/deployment.yml
kubectl apply -f devhub-backend/service.yml

echo "Applying Frontend resources..."
kubectl apply -f devhub-frontend/deployment.yml
kubectl apply -f devhub-frontend/service.yml

echo "Applying Ingress..."
kubectl apply -f ingress/devhub-ingress.yml

# ===============================
# 4️⃣ 배포 상태 확인
# ===============================
sleep 5

echo "Pods in devhub-frontend namespace:"
kubectl get pods -n devhub-frontend

echo "Services in devhub-frontend namespace:"
kubectl get svc -n devhub-frontend

echo "Ingress in devhub-frontend namespace:"
kubectl get ingress -n devhub-frontend

# ===============================
# 5️⃣ Minikube Ingress 접속 안내
# ===============================
echo "✅ Deployment complete!"
echo "To access devhub.local from your browser:"
echo "1. Ensure your /etc/hosts has the mapping:"
echo "   <Minikube IP> devhub.local"
echo "   (Find Minikube IP with 'minikube ip')"
echo "2. Forward Ingress Controller port:"
echo "   kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80"
echo "3. Open browser: http://devhub.local"