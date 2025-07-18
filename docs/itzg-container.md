# itzg 컨테이너 이미지 상세 분석

## itzg/minecraft-server

### 메모리 할당
- **MEMORY**: 기본값 1G, JVM 힙 메모리 설정 (Xms, Xmx)
- **INIT_MEMORY**: 초기 힙 사이즈 독립 설정
- **MAX_MEMORY**: 최대 힙 사이즈 독립 설정
- **USE_AIKAR_FLAGS**: true 설정 시 GC 최적화 플래그 적용

### Paper 서버 설정
- **TYPE=PAPER**: Paper 서버 타입
- **SERVER_PORT**: 서버 포트 (기본값 25565)
- **ONLINE_MODE**: 기본값 true, Velocity 사용 시 false 설정
- **EULA=TRUE**: 필수 설정

### 데이터 디렉터리 구조
```
/data/
├── world/                 # 메인 월드 데이터
├── world_nether/         # 네더 월드
├── world_the_end/        # 엔드 월드
├── plugins/              # 플러그인 파일들
├── server.properties     # 서버 설정 파일
├── ops.json             # 관리자 목록
├── whitelist.json       # 화이트리스트
├── banned-players.json  # 차단된 플레이어
└── logs/                # 서버 로그
```

### 리소스 최적화 설정
```yaml
# EC2 리소스 최대 활용 예시 (r6g.large: 2 vCPU, 8GB RAM)
environment:
  MEMORY: "7G"                    # 7GB 할당 (1GB 시스템 여유)
  USE_AIKAR_FLAGS: "true"         # GC 최적화
  JVM_XX_OPTS: "-XX:+UseG1GC"     # G1GC 사용
```

## itzg/docker-mc-proxy (Velocity)

### 기본 설정
- **TYPE=VELOCITY**: Velocity 프록시 타입
- **MEMORY**: 기본값 512m, 프록시는 적은 메모리 사용
- **포트**: 25565 (Velocity 기본 포트)

### Velocity 서버 설정
- **VELOCITY_SERVERS**: 백엔드 서버 목록 설정
  ```
  VELOCITY_SERVERS: |
    lobby:host=paperserver.internal:25501
    wild:host=paperserver.internal:25502
    village:host=paperserver.internal:25503
  ```

### 리소스 최적화 설정
```yaml
# EC2 리소스 최대 활용 예시 (t4g.nano: 2 vCPU, 0.5GB RAM)
environment:
  MEMORY: "400m"                  # 400MB 할당 (100MB 시스템 여유)
  JVM_OPTS: "-XX:+UseSerialGC"    # 적은 메모리에 적합한 GC
```

## Paper Server EC2 Docker Compose 구성

### 하드웨어 사양
- **인스턴스 타입**: r6g.xlarge (4 vCPU, 32GB RAM)
- **메모리 배분**: 
  - lobby-server: 8GB
  - wild-server: 10GB 
  - village-server: 10GB
  - 시스템 여유: 4GB

### Docker Compose 예시
```yaml
# docker-compose.yml
version: '3.8'
services:
  lobby-server:
    image: itzg/minecraft-server:latest
    container_name: lobby-server
    ports:
      - "25501:25565"
    environment:
      EULA: "true"
      TYPE: "PAPER"
      MEMORY: "8G"
      USE_AIKAR_FLAGS: "true"
      ONLINE_MODE: "false"
    volumes:
      - /data/lobby:/data
      - /data/shared:/data/shared:ro
      - /data/players:/data/players
    restart: unless-stopped

  wild-server:
    image: itzg/minecraft-server:latest
    container_name: wild-server
    ports:
      - "25502:25565"
    environment:
      EULA: "true"
      TYPE: "PAPER"
      MEMORY: "10G"
      USE_AIKAR_FLAGS: "true"
      ONLINE_MODE: "false"
    volumes:
      - /data/wild:/data
      - /data/shared:/data/shared:ro
      - /data/players:/data/players
    restart: unless-stopped

  village-server:
    image: itzg/minecraft-server:latest
    container_name: village-server
    ports:
      - "25503:25565"
    environment:
      EULA: "true"
      TYPE: "PAPER"
      MEMORY: "10G"
      USE_AIKAR_FLAGS: "true"
      ONLINE_MODE: "false"
    volumes:
      - /data/village:/data
      - /data/shared:/data/shared:ro
      - /data/players:/data/players
    restart: unless-stopped
```

## EBS 볼륨 구조 분석

### 로컬 블록 스토리지 구조
EBS GP3 볼륨을 `/data`에 마운트하여 다음과 같이 구성:

```
/data/ (EBS GP3 50GB)
├── shared/
│   ├── plugins/          # 공통 플러그인 (모든 서버 공유)
│   └── configs/          # 공통 설정 파일
├── lobby/
│   ├── world/           # 로비 전용 월드
│   └── plugins/         # 로비 전용 플러그인
├── wild/
│   ├── world/           # 야생 전용 월드
│   └── plugins/         # 야생 전용 플러그인
├── village/
│   ├── world/           # 마을 전용 월드
│   └── plugins/         # 마을 전용 플러그인
└── players/             # 플레이어 데이터 (모든 서버 공유)
    ├── playerdata/      # 플레이어 인벤토리/위치 등
    └── stats/           # 플레이어 통계
```

### 컨테이너별 마운트 설정
```yaml
# Lobby 서버 컨테이너
volumes:
  - /data/lobby:/data
  - /data/shared:/data/shared:ro
  - /data/players:/data/players

# Wild 서버 컨테이너  
volumes:
  - /data/wild:/data
  - /data/shared:/data/shared:ro
  - /data/players:/data/players

# Village 서버 컨테이너
volumes:
  - /data/village:/data
  - /data/shared:/data/shared:ro
  - /data/players:/data/players
```

## 최적화된 리소스 할당

### t4g.nano (Velocity Proxy)
- **CPU**: 2 vCPU (100% 활용 가능)
- **Memory**: 0.5GB 중 0.4GB Java 할당
- **네트워크**: 최대 5Gbps

### r6g.xlarge (Paper Server - 통합)
- **CPU**: 4 vCPU (100% 활용 가능)
- **Memory**: 32GB 중 28GB Java 할당 (lobby: 8GB, wild: 10GB, village: 10GB)
- **네트워크**: 최대 10Gbps
- **관리 편의성**: 단일 EC2에서 Docker Compose로 통합 관리

### 단일 EC2 + Docker Compose 아키텍쳐 수정
- **비용 효율**: 3대 EC2 → 1대 EC2로 비용 절감, EBS GP3로 75% 스토리지 비용 절감
- **관리 편의**: 단일 서버에서 모든 Paper Server 관리
- **자원 효율**: 유휴 자원 공유로 리소스 최적화
- **배포 간소화**: Docker Compose 단일 명령으로 모든 서버 배포
- **성능 향상**: 로컬 블록 스토리지로 낮은 레이턴시 (1ms vs 2.7ms)
