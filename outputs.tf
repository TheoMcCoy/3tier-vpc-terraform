output "vpc_id" {
    value = aws_vpc.main.id  
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

output "web_instance" {
  value = aws_instance.web[*].id
}

output "aurora_cluster_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  value = aws_rds_cluster.aurora.reader_endpoint
}