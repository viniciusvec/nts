################################### IAM

######### Execution role #########

# IAM Role for ECS Task Execution  
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Necessary AWS-managed Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

######## Task role #########

# IAM Role for ECS Task Setup
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Custom policy for using RDS
resource "aws_iam_policy" "ecs_to_rds_task_policy" {
  name        = "ecsTaskPolicy"
  description = "Policy for ECS tasks to access RDS cluster"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds-db:connect"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "s3:Get*"
        ]
        Resource = "*"
      }
    ]
  })
  #depends_on = [aws_rds_cluster.rds_cluster]
}

# Attach custom RDS execution Policy
resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_to_rds_task_policy.arn
}


resource "aws_ecs_cluster" "nts_webapp" {
  name = "webapp-cluster"
}

################################### SG

# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Allow traffic to ECS"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_into_ecs" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow HTTP inbound traffic from ALB SG"

  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_mysql_out_to_rds" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow mysql outbound traffic to RDS"

  referenced_security_group_id = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_https_out_to_internet" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "Allow https outbound traffic to internet"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

################################### ECS  

# ECS Task Definition 
resource "aws_ecs_task_definition" "nts_webapp" {
  family                   = var.family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 256 CPU units equate to 0.25 vCPUs
  memory                   = "512" # 512 MiB

  container_definitions = jsonencode([
    {
      name  = var.container_display_name_nts_webapp
      image = "${aws_ecr_repository.ecr_image_repo.repository_url}",
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  depends_on = [aws_lb.alb]
}

# ECS Service 
resource "aws_ecs_service" "nts_webapp" {
  name            = "ntswebapp-service"
  cluster         = aws_ecs_cluster.nts_webapp.id
  task_definition = aws_ecs_task_definition.nts_webapp.arn
  desired_count   = 1 # Size reduced to speed up dev environment
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id, aws_subnet.private_subnet3.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nts_webapp_tg.arn
    container_name   = var.container_display_name_nts_webapp
    container_port   = 80
  }
}
