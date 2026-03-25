resource "aws_db_subnet_group" "aurora" {
  name = "${local.project}-aurora-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id
  tags = local.common_tags
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${local.project}-aurora-cluster"
  engine = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.04.0"
  database_name = "appdb"
  master_username = "admin"
  master_password = var.db_master_password 
  db_subnet_group_name = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot = true
  backup_retention_period = 7
  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "aurora" {
  count = 2
  identifier = "${local.project}-aurora-${count.index == 0 ? "primary" : "replica"}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class = var.db_instance_class
  engine = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version
  availability_zone = var.availability_zones[count.index]
  publicly_accessible = false
  tags = merge(local.common_tags, {Name = count.index == 0 ? "primary" : "replica"})
}