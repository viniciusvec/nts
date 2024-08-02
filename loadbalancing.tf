
################################## ALB 
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}

# ALB Target Group 
resource "aws_lb_target_group" "nts_webapp_tg" {
  name        = "nts-webapp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Specify the target type as 'ip' 

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

# ALB Listener 
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nts_webapp_tg.arn
  }
}


################################### SG

# Security Group for ALB 
resource "aws_security_group" "alb_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Allow traffic to ALB"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_into_alb" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP inbound traffic from ALB SG"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_http_out_to_ecs" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP outbound traffic to ECS"

  referenced_security_group_id = aws_security_group.ecs_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}


################################### Outputs


output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}
