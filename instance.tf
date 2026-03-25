data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  count = 2
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name = var.key_pair_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Server ${count.index + 1} — AZ: $(curl -s
      http://169.254.169.254/latest/meta-data/placement/availability-zone)</h1>" \
      > /var/www/html/index.html
  EOF

  tags = merge(local.common_tags, {Name = "${local.project}-web-${count.index + 1}"
  Tier = "Web"})
}

resource "aws_instance" "app" {
  count = 2
  ami = data.aws_ami.amazon_linux_2
  instance_type = var.instance_type
  subnet_id = aws_subnet.private_app[count.index].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name = var.key_pair_name

  tags = merge(local.common_tags, {Name = "${local.project}-web-${count.index + 1}"
  Tier = "App"})
}