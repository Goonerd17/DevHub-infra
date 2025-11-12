#!/bin/bash
set -e

# ===============================
# 1️⃣ Minikube 시작
# ===============================
echo "Starting Minikube..."
minikube start --driver=docker --cpus=4 --memory=4096

minikube image load registry.k8s.io/ingress-nginx/controller:v1.13.2
minikube image load registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.2

echo "Enabling ingress..."
minikube addons enable ingress || true

echo "Waiting for ingress controller to be ready..."
kubectl -n ingress-nginx wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=180s

# ===============================
# 2️⃣ K8s 리소스 적용 (통합 네임스페이스)
# ===============================
cd /c/DevHub-infra/infra/k8s

# 1️⃣ Backend Namespace 먼저 생성
echo "Applying Backend namespace..."
kubectl apply -f devhub-backend/namespace.yml

# 2️⃣ Backend Deployment + Service 생성
echo "Applying Backend resources..."
kubectl apply -f devhub-backend/deployment.yml
kubectl apply -f devhub-backend/service.yml

# 3️⃣ Frontend Namespace 생성
echo "Applying Frontend namespace..."
kubectl apply -f devhub-frontend/namespace.yml

# 4️⃣ Frontend Deployment + Service 생성
echo "Applying Frontend resources..."
kubectl apply -f devhub-frontend/deployment.yml
kubectl apply -f devhub-frontend/service.yml

# 5️⃣ Ingress 적용
echo "Applying Ingress..."
kubectl apply -f ingress/devhub-ingress.yml

# ===============================
# 3️⃣ 배포 상태 확인
# ===============================
sleep 5

echo "Pods in devhub-frontend namespace:"
kubectl get pods -n devhub-frontend

echo "Services in devhub-frontend namespace:"
kubectl get svc -n devhub-frontend

echo "Ingress in devhub-frontend namespace:"
kubectl get ingress -n devhub-frontend

# ===============================
# 4️⃣ Minikube Ingress 접속 안내
# ===============================
echo "✅ Deployment complete!"
echo "To access devhub.local from your browser:"
echo "1. Ensure your /etc/hosts has the mapping:"
echo "   <Minikube IP> devhub.local"
echo "   (Find Minikube IP with 'minikube ip')"
echo "2. Forward Ingress Controller port:"
echo "   kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80"
echo "3. Open browser: http://devhub.local"