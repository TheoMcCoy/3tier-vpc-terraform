resource "aws_lb" "web" {
  name = "${local.project}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = aws_subnet.public[*].id
  tags = local.common_tags
}

# Target Group
resource "aws_lb_target_group" "web" {
  name = "${local.project}-web-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Register Web EC2 as targets
resource "aws_lb_target_group_attachment" "web" {
  count = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id = aws_instance.web[count.index].id
  port = 80
}

# HTTP Listener
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.web.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.web.arn
    }
}