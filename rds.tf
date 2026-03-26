resource "aws_db_subnet_group" "db" {
  name       = "${local.project}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id
  tags       = local.common_tags
}

resource "aws_db_instance" "database" {
  identifier        = "${local.project}-db-instance"
  engine            = "postgres"
  engine_version    = "15.17"
  instance_class    = "db.t3.micro" 
  allocated_storage = 20            

  db_name  = "appdb"
  username = "dbadmin"
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = 1    
  skip_final_snapshot     = true 
  multi_az                = false 
  publicly_accessible     = false

  tags = local.common_tags
}

# resource "aws_db_instance" "database_replica" {
#   identifier          = "${local.project}-db-replica"
#   replicate_source_db = aws_db_instance.database.identifier
#   instance_class      = "db.t3.micro"

#   publicly_accessible = false
#   skip_final_snapshot = true
#   multi_az            = false

#   vpc_security_group_ids = [aws_security_group.db.id]

#   tags = local.common_tags
# }