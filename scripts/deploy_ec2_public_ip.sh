#!/bin/bash
# ==============================================================================
# DEPLOY OTOMATIS: WSL2 Ubuntu -> AWS EC2 Ubuntu -> Elastic IP -> Docker
# Hasil: aplikasi dapat diakses via http://<IP-PUBLIK> (bukan localhost)
# ==============================================================================
set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
KEY_NAME="${KEY_NAME:-uts-cloud-key}"
PROJECT_DIR="$HOME/ec2-public-ip-deploy"
SSH_KEY_PATH="$HOME/.ssh/uts-cloud-key"
PUB_KEY_PATH="$HOME/.ssh/uts-cloud-key.pub"

echo "============================================================"
echo " [1/5] PERSIAPAN TOOLS & KREDENSIAL AWS"
echo "============================================================"
command -v aws >/dev/null || { sudo apt-get update -y && sudo apt-get install -y awscli; }
command -v terraform >/dev/null || {
  wget -O- https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -y && sudo apt-get install -y terraform
}
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Kredensial AWS tidak valid. Jalankan: rm -rf ~/.aws && aws login"
  exit 1
fi
echo "Kredensial AWS OK."

echo "============================================================"
echo " [2/5] SSH KEY PAIR RSA 4096"
echo "============================================================"
mkdir -p ~/.ssh
if [ ! -f "$PUB_KEY_PATH" ]; then
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
fi
chmod 400 "$SSH_KEY_PATH"

echo "============================================================"
echo " [3/5] TERRAFORM: EC2 + SECURITY GROUP + ELASTIC IP"
echo "============================================================"
mkdir -p "$PROJECT_DIR" && cd "$PROJECT_DIR"

AMI_ID=$(aws ec2 describe-images \
  --region "$AWS_REGION" --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

cat > main.tf <<EOF
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = "$AWS_REGION" }

resource "aws_security_group" "web_sg" {
  name = "web-uts-sg-public"
  ingress {
    from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "deployer" {
  key_name = "$KEY_NAME"
  public_key = file("$PUB_KEY_PATH")
}
resource "aws_instance" "web" {
  ami = "$AMI_ID"
  instance_type = "$INSTANCE_TYPE"
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = { Name = "web-uts-public" }
}
resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain = "vpc"
}
output "public_ip" { value = aws_eip.web_eip.public_ip }
output "instance_id" { value = aws_instance.web.id }
EOF

terraform init
terraform apply -auto-approve
PUBLIC_IP=$(terraform output -raw public_ip)
echo ">>> IP PUBLIK: $PUBLIC_IP <<<"

echo "============================================================"
echo " [4/5] MENUNGGU EC2 SIAP + INSTALL DOCKER VIA SSH"
echo "============================================================"
echo "Menunggu 30 detik..."
sleep 30

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" ubuntu@"$PUBLIC_IP" <<'ENDSSH'
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo systemctl enable --now docker
  sudo usermod -aG docker ubuntu
  mkdir -p ~/web && cd ~/web
  cat > index.html <<'EOF'
<!DOCTYPE html>
<html><body style="text-align:center;margin-top:50px;font-family:sans-serif">
<h1>Halo dari IP Publik EC2!</h1>
<p>Container Docker berjalan normal.</p>
</body></html>
EOF
  cat > Dockerfile <<'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EOF
  sudo docker build -t web-public:v1 .
  sudo docker run -d --name web-public --restart unless-stopped -p 80:80 web-public:v1
  echo "Docker aktif."
ENDSSH

echo "============================================================"
echo " [5/5] SELESAI"
echo "============================================================"
echo "Akses aplikasi : http://$PUBLIC_IP"
echo "SSH            : ssh -i $SSH_KEY_PATH ubuntu@$PUBLIC_IP"
echo "Hapus resource : cd $PROJECT_DIR && terraform destroy"
echo "============================================================"
