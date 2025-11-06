# DevHub-infra

```markdown
# DevHub Infra Environment Setup

이 프로젝트는 Vagrant와 Ansible을 사용하여 **로컬 VM 환경에서 개발 및 테스트 환경을 자동으로 구축**하는 예제입니다.  
주요 목표는 **VM 생성 → Ansible 설치 → Docker, Jenkins, Minikube, ArgoCD 환경 세팅**까지 자동화하는 것입니다.

---

## Vagrantfile 설명

- **VM 기본 설정**
  - Box: `ubuntu/jammy64` (Ubuntu 22.04 LTS)
  - Hostname: `devhub-vm`
  - Private Network IP: `192.168.56.10`
- **VirtualBox 리소스**
  - CPU: 2, Memory: 4096MB, GUI: false
- **SSH**
  - 기본 Vagrant 키 사용 (username/password 지정 불필요)
- **Ansible**
  - VM 내부 설치 (`shell provisioner`)
  - VM 내부 실행 (`ansible_local provisioner`)
  - 호스트의 ansible 폴더 동기화: `/vagrant/ansible`

---

## Vagrant + Ansible 실행 흐름

```text
Host PC (Windows)
├─ Vagrantfile 실행: vagrant up
│
├─ VirtualBox
│  └─ VM 생성 (Ubuntu 22.04)
│
└─ Guest VM
   ├─ Shell Provisioner
   │   └─ Ansible 설치
   │
   └─ ansible_local
       └─ Playbook 실행
           ├─ common role
           ├─ docker role
           ├─ jenkins role
           ├─ minikube role
           └─ argocd role
````

---

## Host vs Guest Provisioning

| 구분                     | 의미                                | Vagrant 예시                                                             |
| ---------------------- | --------------------------------- | ---------------------------------------------------------------------- |
| **Host provisioning**  | 호스트 OS에서 명령어나 스크립트를 실행하여 VM 환경 설정 | `config.vm.provision "ansible"` (호스트에 설치된 Ansible 사용)                  |
| **Guest provisioning** | VM 내부(OS)에서 스크립트를 실행하여 환경 설정      | `config.vm.provision "shell"` 또는 `config.vm.provision "ansible_local"` |
| **ansible_local**      | VM 내부에서 Ansible 설치 후 playbook 실행  | 지금 프로젝트 방식                                                             |

> 요약: 지금 구조는 **게스트 프로비저닝(Guest Provisioning)** 기반이며, Windows 호스트에 Ansible 설치 필요 없음.

---

## 주요 명령어

### VM 생성 및 환경 구성

```bash
vagrant up
```

### VM 접속

```bash
vagrant ssh
```

### 환경 종료

```bash
vagrant halt
```

### VM 삭제

```bash
vagrant destroy -f
```

### Box 캐시 정리

```bash
vagrant box list
vagrant box remove <box_name>
vagrant global-status --prune
```

---

## 문제 해결 팁

### SSH 연결 실패

* Ubuntu box는 **키 기반 로그인**만 허용
* Vagrantfile에서 `config.ssh.username` / `config.ssh.password` 제거

### VM 이름 충돌

* VirtualBox에 이미 같은 이름의 VM 존재 시 오류 발생
* 해결 방법:

```bash
vagrant destroy -f
VBoxManage list vms
VBoxManage unregistervm "devhub-vm" --delete
```

---

## 실행 순서 요약

1. Vagrant VM 삭제 및 초기화

```bash
vagrant destroy -f
```

2. VM 생성 및 provisioning

```bash
vagrant up
```

3. VM 접속 후 설치 확인

```bash
vagrant ssh
docker --version
jenkins --version
minikube version
argocd version
```

4. VM 종료/삭제

```bash
vagrant halt
vagrant destroy -f
```

---

## 참고 사항

* Windows 호스트에서도 **ansible_local** 사용 시 Ansible 설치 필요 없음
* 호스트와 VM 간 동기화된 폴더(`/vagrant/ansible`)를 통해 playbook 실행
* 향후 필요시 Vagrantfile에서 VM 이름에 버전 번호 추가하여 충돌 방지 가능

