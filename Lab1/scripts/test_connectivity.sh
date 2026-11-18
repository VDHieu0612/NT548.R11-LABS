#!/usr/bin/env bash
# =============================================================================
# NT548.R11 - Lab 01 - Nhom 04
# Script kiem thu ket noi tu dong cho ha tang AWS (Terraform / CloudFormation)
# Phu trach: Hoang Le Nhat Minh (23520926)
#
# Cach dung:
#   bash scripts/test_connectivity.sh <path_key.pem> <PUBLIC_IP> <PRIVATE_IP> [NAT_EIP]
#
#   <path_key.pem> : SSH private key gan voi 2 EC2 (vd: labsuser.pem / vockey)
#   <PUBLIC_IP>    : Public IP cua Bastion Host (Public EC2)
#   <PRIVATE_IP>   : Private IP cua Private EC2
#   [NAT_EIP]      : (tuy chon) Elastic IP cua NAT Gateway, de doi chieu o TC05
#
# Bien moi truong tuy chon:
#   SSH_USER (mac dinh: ec2-user)   CONNECT_TIMEOUT (mac dinh: 10 giay)
#   LOG_DIR  (mac dinh: scripts/logs)
#
# Test case tu dong:
#   TC01  SSH tu may ca nhan vao Public EC2
#   TC02  (kiem tra cau hinh) SG cua Public EC2 khong mo SSH cho 0.0.0.0/0  [can AWS CLI]
#   TC03  Khong the SSH truc tiep vao Private EC2 tu Internet
#         + Private EC2 khong co Public IP                                  [can AWS CLI]
#   TC04  SSH tu Public EC2 sang Private EC2 (Bastion / ProxyCommand)
#         + Ping (ICMP) tu Bastion sang Private EC2
#   TC05  Private EC2 ra Internet qua NAT Gateway (IP ra ngoai = NAT EIP)
#   TC06  Tong hop: script tra ve exit code 0 khi khong co test nao FAILED
# =============================================================================

set -uo pipefail

usage() {
  cat <<EOF
Usage: bash $0 <path_key.pem> <PUBLIC_IP> <PRIVATE_IP> [NAT_EIP]

Vi du (Terraform):
  cd Lab1/terraform/environments/dev
  bash ../../../scripts/test_connectivity.sh ~/.ssh/labsuser.pem \\
       \$(terraform output -raw public_bastion_ip) \\
       \$(terraform output -raw private_instance_internal_ip) \\
       \$(aws ec2 describe-addresses --filters Name=tag:Name,Values=NT548-Lab01-nat-eip \\
           --query 'Addresses[0].PublicIp' --output text)

Vi du (CloudFormation - 3 stack my-vpc / my-sg / my-ec2):
  get() { aws cloudformation describe-stacks --stack-name "\$1" \\
            --query "Stacks[0].Outputs[?OutputKey=='\$2'].OutputValue" --output text; }
  bash Lab1/scripts/test_connectivity.sh ~/.ssh/labsuser.pem \\
       \$(get my-ec2 PublicEC2IP) \\
       \$(get my-ec2 PrivateEC2InternalIP) \\
       \$(get my-vpc NatPublicIP)
EOF
  exit 2
}

[[ $# -lt 3 || $# -gt 4 ]] && usage

KEY="$1"
PUBLIC_IP="$2"
PRIVATE_IP="$3"
NAT_EIP="${4:-}"
SSH_USER="${SSH_USER:-ec2-user}"
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-10}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${LOG_DIR:-$SCRIPT_DIR/logs}"

# ---------------------------------------------------------------- Mau & log ---
if [[ -t 1 ]]; then
  GREEN=$'\e[1;32m'; RED=$'\e[1;31m'; YELLOW=$'\e[1;33m'; CYAN=$'\e[1;36m'; NC=$'\e[0m'
else
  GREEN=""; RED=""; YELLOW=""; CYAN=""; NC=""
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_$(date +%Y%m%d_%H%M%S).log"
# Ghi ra man hinh (co mau) va ghi file log (da loai bo ma mau) de nop minh chung
exec > >(tee >(sed -r 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE")) 2>&1

PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
RESULTS=()

record() { # record <ID> <PASSED|FAILED|SKIPPED> <ten test> <chi tiet>
  local id="$1" status="$2" name="$3" detail="$4" color
  case "$status" in
    PASSED)  color="$GREEN";  PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAILED)  color="$RED";    FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    *)       color="$YELLOW"; SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
  esac
  printf '  => %s[%s]%s %s - %s\n' "$color" "$status" "$NC" "$id" "$detail"
  RESULTS+=("$(printf '%-6s %-8s %s' "$id" "$status" "$name")")
}

header() { printf '\n%s---- %s ----%s\n' "$CYAN" "$1" "$NC"; }

is_ipv4() { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }

# ---------------------------------------------------------- Kiem tra dau vao ---
[[ -f "$KEY" ]] || { echo "${RED}Khong tim thay key: $KEY${NC}"; exit 2; }
for ip in "$PUBLIC_IP" "$PRIVATE_IP" ${NAT_EIP:+"$NAT_EIP"}; do
  is_ipv4 "$ip" || { echo "${RED}Dia chi IP khong hop le: $ip${NC}"; exit 2; }
done
command -v ssh >/dev/null || { echo "${RED}Khong tim thay lenh ssh${NC}"; exit 2; }
chmod 400 "$KEY" 2>/dev/null || true

SSH_COMMON=(-i "$KEY" -o BatchMode=yes -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
            -o ConnectTimeout="$CONNECT_TIMEOUT")
# Luu y: tuy chon -J (ProxyJump) KHONG truyen -i sang jump host, nen dung
# ProxyCommand de ca 2 chang SSH deu dung cung mot key.
PROXY_CMD="ssh -i '$KEY' -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=$CONNECT_TIMEOUT -W %h:%p $SSH_USER@$PUBLIC_IP"

ssh_public()  { ssh "${SSH_COMMON[@]}" "$SSH_USER@$PUBLIC_IP" "$@"; }
ssh_private() { ssh "${SSH_COMMON[@]}" -o ProxyCommand="$PROXY_CMD" "$SSH_USER@$PRIVATE_IP" "$@"; }

HAS_AWS=0
if command -v aws >/dev/null && aws sts get-caller-identity >/dev/null 2>&1; then
  HAS_AWS=1
fi

echo "=================================================================="
echo " NT548 Lab01 - Kiem thu ket noi tu dong"
echo " Thoi gian    : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo " Public EC2   : $PUBLIC_IP"
echo " Private EC2  : $PRIVATE_IP"
echo " NAT EIP      : ${NAT_EIP:-<khong cung cap>}"
echo " AWS CLI      : $([[ $HAS_AWS -eq 1 ]] && echo 'co (bat kiem tra cau hinh)' || echo 'khong co / chua dang nhap')"
echo " May kiem thu : IP ra Internet = $(curl -s --max-time 5 https://checkip.amazonaws.com 2>/dev/null || echo 'khong xac dinh')"
echo " Log file     : $LOG_FILE"
echo "=================================================================="

# --------------------------------------------------------------------- TC01 ---
header "TC01: SSH tu may ca nhan vao Public EC2 ($PUBLIC_IP)"
if OUT=$(ssh_public 'echo "hostname=$(hostname)"; uptime' 2>&1); then
  echo "$OUT" | sed 's/^/     /'
  record TC01 PASSED "SSH vao Public EC2" "Ket noi SSH thanh cong"
else
  echo "$OUT" | sed 's/^/     /'
  record TC01 FAILED "SSH vao Public EC2" "Khong SSH duoc (kiem tra key, SG port 22, IP whitelist)"
fi

# --------------------------------------------------------------------- TC02 ---
header "TC02: Public SG chi cho phep SSH tu IP whitelist"
echo "     (Kiem thu thuc te can SSH tu mot IP khac - xem huong dan thu cong trong bao cao)"
if [[ $HAS_AWS -eq 1 ]]; then
  SG_IDS=$(aws ec2 describe-instances \
            --filters "Name=ip-address,Values=$PUBLIC_IP" "Name=instance-state-name,Values=running" \
            --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text 2>/dev/null)
  if [[ -z "$SG_IDS" || "$SG_IDS" == "None" ]]; then
    record TC02 SKIPPED "SG SSH whitelist" "Khong tim thay instance co IP $PUBLIC_IP trong region hien tai"
  else
    # shellcheck disable=SC2086
    CIDRS=$(aws ec2 describe-security-groups --group-ids $SG_IDS \
             --query 'SecurityGroups[].IpPermissions[?FromPort<=`22` && ToPort>=`22`].IpRanges[].CidrIp' \
             --output text 2>/dev/null | tr '\t' ' ')
    echo "     Security Group: $SG_IDS"
    echo "     CIDR duoc phep SSH: ${CIDRS:-<khong co>}"
    if [[ -z "$CIDRS" ]]; then
      record TC02 FAILED "SG SSH whitelist" "Khong co rule SSH nao tren Public SG"
    elif [[ " $CIDRS " == *" 0.0.0.0/0 "* ]]; then
      record TC02 FAILED "SG SSH whitelist" "SSH dang mo cho 0.0.0.0/0 (sai yeu cau)"
    else
      record TC02 PASSED "SG SSH whitelist" "SSH chi mo cho: $CIDRS"
    fi
  fi
else
  record TC02 SKIPPED "SG SSH whitelist" "Can AWS CLI da dang nhap; hoac kiem thu thu cong"
fi

# --------------------------------------------------------------------- TC03 ---
header "TC03: Khong the SSH truc tiep vao Private EC2 tu Internet"
if ssh -o ConnectTimeout=5 "${SSH_COMMON[@]}" "$SSH_USER@$PRIVATE_IP" 'true' >/dev/null 2>&1; then
  TC03_DIRECT=FAIL
  echo "     SSH truc tiep vao $PRIVATE_IP THANH CONG - sai yeu cau"
else
  TC03_DIRECT=OK
  echo "     SSH truc tiep vao $PRIVATE_IP that bai/timeout (dung ky vong)"
fi
TC03_PUBIP=SKIP
if [[ $HAS_AWS -eq 1 ]]; then
  PRIV_PUB=$(aws ec2 describe-instances \
              --filters "Name=private-ip-address,Values=$PRIVATE_IP" "Name=instance-state-name,Values=running" \
              --query 'Reservations[].Instances[].PublicIpAddress' --output text 2>/dev/null)
  if [[ -z "$PRIV_PUB" || "$PRIV_PUB" == "None" ]]; then
    TC03_PUBIP=OK;   echo "     Private EC2 khong co Public IP (dung ky vong)"
  else
    TC03_PUBIP=FAIL; echo "     Private EC2 dang co Public IP: $PRIV_PUB (sai yeu cau)"
  fi
fi
if [[ $TC03_DIRECT == OK && $TC03_PUBIP != FAIL ]]; then
  record TC03 PASSED "Chan SSH truc tiep vao Private EC2" "Khong truy cap duoc tu Internet"
else
  record TC03 FAILED "Chan SSH truc tiep vao Private EC2" "Private EC2 bi lo ra Internet"
fi

# --------------------------------------------------------------------- TC04 ---
header "TC04: SSH tu Public EC2 (Bastion) sang Private EC2 ($PRIVATE_IP)"
if OUT=$(ssh_private 'echo "hostname=$(hostname)"; echo "ip=$(hostname -I)"' 2>&1) \
   && grep -qw "$PRIVATE_IP" <<<"$OUT"; then
  echo "$OUT" | sed 's/^/     /'
  record TC04 PASSED "SSH Bastion -> Private EC2" "Ket noi qua Bastion thanh cong"
else
  echo "$OUT" | sed 's/^/     /'
  record TC04 FAILED "SSH Bastion -> Private EC2" "Khong SSH duoc qua Bastion (kiem tra Private SG)"
fi

header "TC04b: Ping (ICMP) tu Bastion sang Private EC2"
if OUT=$(ssh_public "ping -c 3 -W 2 $PRIVATE_IP" 2>&1); then
  echo "$OUT" | tail -n 2 | sed 's/^/     /'
  record TC04b PASSED "Ping Bastion -> Private EC2" "Private SG cho phep ICMP tu Public SG"
else
  echo "$OUT" | tail -n 2 | sed 's/^/     /'
  record TC04b FAILED "Ping Bastion -> Private EC2" "ICMP bi chan"
fi

# --------------------------------------------------------------------- TC05 ---
header "TC05: Private EC2 ra Internet qua NAT Gateway"
EGRESS_IP=$(ssh_private 'curl -s --max-time 10 https://checkip.amazonaws.com || curl -s --max-time 10 ifconfig.me' 2>/dev/null | tr -d '[:space:]')
HTTP_CODE=$(ssh_private "curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://www.google.com" 2>/dev/null)
echo "     IP ra Internet cua Private EC2 : ${EGRESS_IP:-<khong lay duoc>}"
echo "     HTTP code khi goi google.com   : ${HTTP_CODE:-<khong co>}"
if ! is_ipv4 "${EGRESS_IP:-x}"; then
  record TC05 FAILED "Private EC2 ra Internet qua NAT" "Private EC2 khong ra duoc Internet (kiem tra NAT GW / route)"
elif [[ -n "$NAT_EIP" && "$EGRESS_IP" != "$NAT_EIP" ]]; then
  record TC05 FAILED "Private EC2 ra Internet qua NAT" "IP ra ngoai ($EGRESS_IP) khac NAT EIP ($NAT_EIP)"
elif [[ -n "$NAT_EIP" ]]; then
  record TC05 PASSED "Private EC2 ra Internet qua NAT" "IP ra ngoai trung khop NAT EIP $NAT_EIP"
else
  record TC05 PASSED "Private EC2 ra Internet qua NAT" "Ra Internet duoc voi IP $EGRESS_IP (chua doi chieu NAT EIP)"
fi

# ------------------------------------------------------------- TC06 / Tong ket ---
header "TC06: Tong hop ket qua"
printf '     %-6s %-8s %s\n' "ID" "KETQUA" "TEN TEST"
for r in "${RESULTS[@]}"; do echo "     $r"; done
echo
echo "     PASSED: $PASS_COUNT | FAILED: $FAIL_COUNT | SKIPPED: $SKIP_COUNT"
if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "  => ${GREEN}[PASSED]${NC} TC06 - Tat ca assertions deu PASSED"
  EXIT_CODE=0
else
  echo "  => ${RED}[FAILED]${NC} TC06 - Co $FAIL_COUNT test FAILED"
  EXIT_CODE=1
fi
echo "     Log da luu tai: $LOG_FILE"
exit $EXIT_CODE
