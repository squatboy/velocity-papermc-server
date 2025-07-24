#!/bin/bash

# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Velocity Proxy EC2 User Data Script Started at $(date) ==="

# 시스템 업데이트
apt-get update
apt-get upgrade -y
echo "System updated successfully."

# Docker 설치
curl -fsSL https://get.docker.sh -o get-docker.sh
sh get-docker.sh
echo "Docker installed successfully."
usermod -aG docker ubuntu
echo "User 'ubuntu' added to 'docker' group."

# Docker 서비스 시작
systemctl start docker
systemctl enable docker
echo "Docker service started and enabled."

# SSM Agent 설치 및 시작
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
echo "SSM Agent started and enabled."


# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Docker 서비스 시작
systemctl start docker
systemctl enable docker

# SSM Agent 설치 및 시작
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# --- EBS 볼륨 마운트 설정 ---
echo "=== EBS Volume Setup for Velocity ==="
MOUNT_POINT="/mcserver/velocity"
DEVICE_PATH=""
MAX_RETRIES=60 # 5분 (60회 * 5초)
RETRY_COUNT=0

# 부팅 시점의 블록 디바이스 상태를 로그로 기록
echo "Initial block device state:"
lsblk

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # 루트 파티션('/')이 있는 디바이스를 찾아서 제외
  ROOT_DEVICE=$(lsblk -no pkname $(findmnt -n -o SOURCE /))
  
  # /dev/sd* 또는 /dev/xvd* 또는 /dev/nvme* 형태의 모든 블록 디바이스를 순회
  for device in $(ls /dev/{sd,xvd,nvme}*n* 2>/dev/null | grep -vE 'p[0-9]+$'); do
    # 디바이스가 루트 디바이스인지 확인
    if [[ "$device" == "/dev/$ROOT_DEVICE" ]]; then
      echo "Skipping root device: $device"
      continue
    fi

    # 파티션이 없는 순수 디스크인지 확인
    if [ -b "$device" ] && ! lsblk -n "$device" | grep -q "part"; then
      DEVICE_PATH="$device"
      echo "Found attached EBS volume: $DEVICE_PATH"
      break 2
    fi
  done

  if [ -n "$DEVICE_PATH" ]; then
    break
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Waiting for EBS volume to attach... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 5
done

# 최종 블록 디바이스 상태를 로그로 기록
echo "Final block device state:"
lsblk

# 디바이스를 여전히 찾지 못한 경우 에러
if [ -z "$DEVICE_PATH" ]; then
  echo "ERROR: EBS volume device not found after $MAX_RETRIES attempts."
  exit 1
fi

# 파일시스템 확인 및 생성 (ext4)
if ! blkid -o value -s TYPE ${DEVICE_PATH}; then
  echo "Creating ext4 filesystem on ${DEVICE_PATH}"
  mkfs.ext4 ${DEVICE_PATH}
  echo "Filesystem created on ${DEVICE_PATH}"
fi

# 마운트 포인트 생성
mkdir -p ${MOUNT_POINT}
echo "Mount point ${MOUNT_POINT} created."

# 마운트
mount ${DEVICE_PATH} ${MOUNT_POINT}
chown -R ubuntu:ubuntu ${MOUNT_POINT}
echo "EBS volume ${DEVICE_PATH} mounted to ${MOUNT_POINT} and ownership set."

# fstab에 추가 (재부팅 시 자동 마운트)
UUID=$(blkid -s UUID -o value ${DEVICE_PATH})
if [ -n "$UUID" ] && ! grep -q "UUID=$UUID" /etc/fstab; then
  echo "Adding entry to /etc/fstab for UUID=$UUID."
  echo "UUID=$UUID ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
fi

echo "EBS volume for Velocity mounted successfully on ${MOUNT_POINT}"

# 작업 디렉토리 생성 
mkdir -p /mcserver/velocity
chown ubuntu:ubuntu /mcserver/velocity
echo "Working directory /mcserver/velocity created and ownership set."

# Velocity 서버 Docker 컨테이너 실행
echo "Starting Velocity Proxy Docker container"
docker run -d \
  -p 25565:25565 \
  -e TYPE="VELOCITY" \
  -e EULA="TRUE" \
  -e MEMORY="512m" \
  -v "${MOUNT_POINT}:/server" \
  --restart unless-stopped \
  -i -t \
  --name velocity-proxy \
  itzg/mc-proxy

echo "=== Velocity Proxy EC2 Setup Completed at $(date) ==="