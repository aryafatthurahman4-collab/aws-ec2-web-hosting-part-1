# WSL2 Ubuntu -> AWS EC2 + IP Publik (Lengkap)

Panduan penuh dari laptop (WSL2 Ubuntu) sampai aplikasi bisa diakses lewat **IP publik**, bukan localhost. Cocok untuk praktik *AWS EC2 Web Hosting Part 1*.

> **Penting:** perintah `wsl --install`, `wsl -l -v`, `wsl --shutdown` dijalankan di **PowerShell Windows**, bukan di terminal Ubuntu. Di dalam Ubuntu pakai `bash`.

---

## 1. Instal alat di WSL2

```bash
sudo apt update
sudo apt install -y gnupg software-properties-common curl wget unzip awscli git
```

### Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform -version
```

## 2. Kredensial AWS (jangan pakai key dummy)

Key contoh `AKIAIOSFODNN7EXAMPLE` akan ditolak AWS dengan `AuthFailure`. Pilih salah satu:

### Opsi A — `aws login` (direkomendasikan, sementara)

```bash
rm -rf ~/.aws
aws login
aws sts get-caller-identity   # harus menampilkan UserId, Account, Arn
```

### Opsi B — IAM Access Key permanen

Buat di AWS Console → IAM → Users → Security credentials → Create access key (CLI), lalu:

```bash
aws configure
# Access Key ID, Secret Access Key, region us-east-1, output json
aws sts get-caller-identity
```

## 3. SSH key pair RSA 4096

```bash
mkdir -p ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/uts-cloud-key -N ""
chmod 400 ~/.ssh/uts-cloud-key
```

## 4. Terraform: EC2 + Elastic IP

`~/ec2-public-ip/main.tf`:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = "us-east-1" }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-uts-sg"
  description = "Allow SSH, HTTP, HTTPS"
  ingress {
    from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443; to_port = 443; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "uts-cloud-key"
  public_key = file("~/.ssh/uts-cloud-key.pub")
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = { Name = "web-uts" }
}

resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain   = "vpc"
}

output "public_ip" { value = aws_eip.web_eip.public_ip }
output "instance_id" { value = aws_instance.web.id }
```

Jalankan:

```bash
cd ~/ec2-public-ip
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
terraform output public_ip
```

IP statis tetap sama walau instance di-stop/start (selama EIP tidak di-release).

## 5. Login & install Docker di EC2

```bash
ssh -i ~/.ssh/uts-cloud-key ubuntu@<PUBLIC_IP>
```

Di dalam EC2:

```bash
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
newgrp docker
docker run hello-world
```

## 6. Build image & jalankan container (akses via IP publik)

```bash
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
curl -I http://localhost
```

Buka browser: **http://&lt;PUBLIC_IP&gt;** — bukan localhost.

## 7. PuTTY (Windows)

1. PuTTYgen → **Load** → pilih `~/.ssh/uts-cloud-key` (filter *All Files*).
2. **Save private key** → `uts-cloud-key.ppk`.
3. PuTTY → Host Name: `ubuntu@<PUBLIC_IP>`.
4. Connection → SSH → Auth → Credentials → pilih `.ppk`.
5. Session → Open → terima host key.

## 8. Bersihkan resource (stop biaya)

Sejak Feb 2024, semua IPv4 publik dikenakan biaya per jam — termasuk EIP yang terhubung.

```bash
cd ~/ec2-public-ip && terraform destroy
```

## 9. Troubleshooting

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| `AuthFailure` | Key dummy | `rm -rf ~/.aws` lalu `aws login` |
| SSH timeout | SG belum buka 22 / EIP belum terikat | Cek inbound rule + EIP association |
| `file not found` | SSH key belum ada | `ssh-keygen -t rsa -b 4096` |
| AMI tidak tersedia | AMI beda per region | Cari AMI Ubuntu 22.04 di region tersebut |
| `dnf: command not found` | Script AL2023 dijalankan di Ubuntu | Pakai `apt`, atau login ke EC2 AL2023 sebagai `ec2-user` |
| Port 80 dipakai Nginx/Apache | Konflik layanan | `sudo systemctl stop nginx` atau ubah port Apache ke 8080 |
| `ufw: command not found` | UFW belum terpasang | `sudo apt install -y ufw && sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw enable` |
| `docker build` gagal | Tidak ada Dockerfile | `pwd && ls -la`, `cd` ke folder proyek |
| `kind: command not found` | kind/helm belum ada | `curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64 && chmod +x && sudo mv` |

## 10. Script otomatis

Gunakan [`scripts/deploy_ec2_public_ip.sh`](../scripts/deploy_ec2_public_ip.sh) untuk menjalankan seluruh alur di atas dalam satu perintah.

## Referensi

- https://developer.hashicorp.com/terraform/tutorials/aws-get-started
- https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs
