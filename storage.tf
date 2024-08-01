################################### SG

# Security Group for RDS  
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow traffic to RDS"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_to_rds" {
  security_group_id = aws_security_group.rds_sg.id
  description       = "Allow mysql inbound traffic from ECS SG"


  referenced_security_group_id = aws_security_group.ecs_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}


################################### RDS


# RDS Subnet Group  
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
}


# # RDS Cluster / Aurora
# #https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html
# resource "aws_rds_cluster" "rds_cluster" {
#   cluster_identifier = "aurora-cluster"
#   engine             = "aurora-mysql"
#   engine_mode        = "provisioned"
#   engine_version     = "8.0"
#   database_name      = "rds_db"
#   master_username    = var.db_username
#   #master_password    = not in use due to below
#   manage_master_user_password = true

#   db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
#   availability_zones   = var.availability_zones #["eu-west-2a", "eu-west-2b"]

#   vpc_security_group_ids = [aws_security_group.rds_sg.id]

#   storage_encrypted   = true
#   apply_immediately   = true
#   skip_final_snapshot = true # consider removing for production

#   serverlessv2_scaling_configuration {
#     max_capacity = 1.0
#     min_capacity = 0.5
#   }

#   tags = {
#     Name = "aurora-cluster"
#   }
# }

# resource "aws_rds_cluster_instance" "aurora_instance" {
#   identifier         = "aurora-cluster-instance-${count.index}"
#   count              = 2
#   cluster_identifier = aws_rds_cluster.rds_cluster.id
#   instance_class     = "db.serverless"
#   engine             = aws_rds_cluster.rds_cluster.engine
#   engine_version     = aws_rds_cluster.rds_cluster.engine_version

# }
