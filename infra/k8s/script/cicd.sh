#!/bin/bash

# -----------------------------
# 설정
# -----------------------------

# Jenkins
JENKINS_URL="http://localhost:7070"
# 환경 변수에서 불러오기 (권장)
JENKINS_USER="Goonerd"
JENKINS_TOKEN="11b9cacd29ee8952c23100c8745ab09e9d"

# Argo CD
ARGO_NAMESPACE_PREFIX="devhub"  # namespace 접두사
ARGO_TIMEOUT=120                 # Argo CD sync timeout (초)
# Argo CD CLI 경로
ARGOCD_CMD="/c/Users/5Finger_Lenovo3/argocd.exe"

# 배포 대상 프로젝트
PROJECTS=("frontend" "backend")

# -----------------------------
# 함수
# -----------------------------

# Jenkins 빌드 트리거 및 완료 대기
trigger_jenkins_build() {
    local project=$1
    local job_name="devhub-$project"

    echo "=============================="
    echo "[JENKINS] $job_name 빌드 시작"

    # 빌드 트리거
    curl -s -X POST "$JENKINS_URL/job/$job_name/build?token=$JENKINS_TOKEN" \
        --user "$JENKINS_USER:$JENKINS_TOKEN"

    # 잠시 대기
    sleep 5

    # 마지막 빌드 번호 조회
    local build_number=$(curl -s "$JENKINS_URL/job/$job_name/lastBuild/buildNumber" \
        --user "$JENKINS_USER:$JENKINS_TOKEN")

    echo "[JENKINS] 빌드 #$build_number 모니터링 중..."

    # 빌드 완료 확인
    while true; do
        local status=$(curl -s "$JENKINS_URL/job/$job_name/$build_number/api/json" \
            --user "$JENKINS_USER:$JENKINS_TOKEN" | jq -r '.result')

        if [ "$status" != "null" ]; then
            echo "[JENKINS] 빌드 완료: $status"
            if [ "$status" != "SUCCESS" ]; then
                echo "[ERROR] $job_name 빌드 실패. 스크립트 종료"
                exit 1
            fi
            break
        fi

        echo "[JENKINS] 빌드 진행 중..."
        sleep 5
    done
}

# Argo CD 동기화 및 완료 대기
sync_argo_cd() {
    local project=$1
    local app_name="devhub-$project"

    echo "=============================="
    echo "[ARGO CD] $app_name 동기화 시작"

    # 앱 존재 여부 확인
    if ! $ARGOCD_CMD app get $app_name 2>/dev/null | grep -q "Name:"; then
        echo "[ARGO CD] 앱이 존재하지 않아 생성합니다: $app_name"
        $ARGOCD_CMD app create $app_name \
            --repo https://github.com/Goonerd17/DevHub-infra.git \
            --path infra/k8s/$app_name \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace "devhub-$project" \
            --sync-policy none
    fi

    # 수동 Sync 실행 (namespace 옵션 제거)
    echo "[ARGO CD] 수동 Sync 실행: $app_name"
    $ARGOCD_CMD app sync $app_name

    # Sync 완료 대기
    $ARGOCD_CMD app wait $app_name --timeout $ARGO_TIMEOUT

    echo "[ARGO CD] $app_name 동기화 완료 (Sync 상태: Synced)"
}


# -----------------------------
# 메인 실행
# -----------------------------

for project in "${PROJECTS[@]}"; do
    trigger_jenkins_build $project
    sync_argo_cd $project
done

echo "=============================="
echo "모든 프로젝트 배포 완료!"
