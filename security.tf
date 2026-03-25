# ALB Security Group
resource "aws_security_group" "alb" {
    name = "${local.project}-alb-sg"
    vpc_id = aws_vpc.main.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP from internet"
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPs from internet"
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = merge(local.common_tags, {Name = "${local.project}-alb-sg"})
}

# Web Security Group
resource "aws_security_group" "web" {
    name = "${local.project}-web-sg"
    vpc_id = aws_vpc.main.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [aws_security_group.alb.id]
        description = "HTTP from ALB"
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = merge(local.common_tags, {Name = "${local.project}-web-sg"})
}

# APP Security Group
resource "aws_security_group" "app" {
    name = "${local.project}-app-sg"
    vpc_id = aws_vpc.main.id
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [aws_security_group.web.id]
        description = "All traffic from Web tier"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = merge(local.common_tags, {Name = "${local.project}-app-sg"})
}

# Database security Group
resource "aws_security_group" "db" {
  name = "${local.project}-db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [aws_security_group.app.id]
    description = "All traffic from App Tier"
  }
  tags = merge(local.common_tags, {Name = "${local.project}-db-sg"})
}