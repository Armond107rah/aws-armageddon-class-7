
# Find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a security group for our web server
resource "aws_security_group" "web_sg" {
  name_prefix = "${var.project_name}-web-"
  description = "Security group for temporary EC2 web server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Allow HTTP from our trusted testing IP
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_sg.id

  description = "Allow HTTP from testing location"
  cidr_ipv4   = var.allowed_http_cidr
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Permit outbound connections
resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.web_sg.id

  description = "Allow outbound IPv4 traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


# Create the EC2 instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = var.instance_profile_name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  # Install and configure the Flask application
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_b64 = base64encode(
      file("${path.module}/../../app/app.py")
    )

    requirements_b64 = base64encode(
      file("${path.module}/../../app/requirements.txt")
    )

    project_name = var.project_name
  })

  tags = {
    Name = "${var.project_name}-web-server"
  }

  depends_on = [
    aws_vpc_security_group_egress_rule.outbound
  ]
}
