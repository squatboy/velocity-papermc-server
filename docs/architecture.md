## 1. 🌐 **네트워크 & 보안**

- **Elastic IP**
  - **목적**: 고정 퍼블릭 IP
  - **상세 내용**: Proxy EC2에 할당, 외부 도메인 연결시 A 레코드로 사용

- **NAT Gateway**
  - **목적**: 인터넷 통신
  - **상세 내용**: Private Subnet EC2의 아웃바운드 처리

- **AWS Shield STD**
  - **목적**: DDoS 보호
  - **상세 내용**: Elastic IP로 유입되는 L3/L4 공격 방어

- **VPC Flow Logs**
  - **목적**: 네트워크 모니터링
  - **상세 내용**:
    - REJECT 트래픽만 S3 버킷에 저장 (비용 최적화)
    - 30일 보관 후 자동 삭제
    - Athena를 통한 보안 이벤트 분석

- **VPC ACL**
  - **목적**: 유입 속도 제한
  - **상세 내용**: 비정상 패킷 초당 N 건 이상 시 차단

- **Security Group**
  - **목적**: 방화벽
  - **상세 내용**:
    - Proxy EC2: TCP 25565 Inbound 허용
    - Paper EC2: Proxy EC2에서 오는 포트 25501–25503 inbound 허용
    - SSH 차단, Session Manager 허용

---

## 2. 🎮 **서버 구조 (컨테이너화)**

- **Proxy EC2**
  - **역할**: Velocity 프록시
  - **사양 & 설정**:
    - `t4g.nano` (2 vCPU/0.5 GB RAM) + `itzg/docker-mc-proxy`
    - `VELOCITY_SERVERS` 환경 변수:
      `lobby:host=paperserver.internal:25501`
      `wild:host=paperserver.internal:25502`
      `village:host=paperserver.internal:25503`

- **Paper Server EC2**
  - **역할**: Paper Servers
  - **사양 & 설정**:
    - `r6g.xlarge` (4 vCPU/32 GB RAM)
    - Docker Compose로 3개 컨테이너 운영:
      - `lobby-server`: `itzg/minecraft-server` (포트 25501)
      - `wild-server`: `itzg/minecraft-server` (포트 25502)
      - `village-server`: `itzg/minecraft-server` (포트 25503)

- **EBS GP3 볼륨**
  - **역할**: 마인크래프트 서버 데이터
  - **사양 & 설정**:
    - `/data`에 200GB GP3 볼륨 마운트
    - 3,000 IOPS, 125 MiBps 기본 성능 (필요시 확장 가능)
    - 로컬 블록 스토리지로 최적 성능 및 비용 효율

- **ECS 전환(추후 예정)**
  - **역할**: 향후 자동화
  - **사양 & 설정**: - 추후 -

---

## 3. 📊 **모니터링**

- **CloudWatch Agent**
  - **목적**: 호스트 메트릭
  - **상세 내용**: CPU, RAM, Network

- **Container Insights**
  - **목적**: 컨테이너 메트릭 & 로그
  - **상세 내용**:
    - Docker Stats → CloudWatch (CPU/Memory/BlkIO)
    - 컨테이너 STDOUT/STDERR → Logs

- **CloudWatch Alarm + Discord 웹훅**
  - **목적**: 알림
  - **상세 내용**: CPU ≥80%, RAM ≥90%, Container Exit, Disk ≥70% → Discord 알림

- **CloudWatch (EBS Metrics)**
  - **목적**: 스토리지 모니터링
  - **상세 내용**: `VolumeReadOps`, `VolumeWriteOps`, `VolumeQueueLength`, `VolumeTotalReadTime` 등

---

## 4. 💾 **백업 & 복구** 🔄

- **AWS Data Lifecycle Manager**
  - **주기 & 보존**:
    - 매 1시간 스냅샷
    - 최근 2개 보존 (2시간 커버)
  - **상세 내용**: EBS 스냅샷 자동 생성 및 관리, 실시간 게임 환경 대응, 증분 백업으로 비용 효율적

- **EventBridge → SSM Run Command**
  - **주기 & 보존**: 비정상 컨테이너 자동 복구
  - **상세 내용**: 컨테이너 Exit 이벤트 수신 → `docker restart $ID`.

---

## 5. 🛠️ **운영자 도구**

- **AWS Systems Manager Session Manager**
  - **기능**: 원격 관리
  - **상세 내용**: SSH 열지 않고 EC2 접속, CloudWatch Logs 감사.

- **CodeDeploy (추후 예정)**
  - **기능**: 무중단 배포
  - **상세 내용**: 새 이미지 Push → 롤링 업데이트.