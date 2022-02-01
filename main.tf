# The bulk of resources are defined here except for the database related resources defined in db.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "${var.aws_region}a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "${var.aws_region}c"
}

resource "aws_ecs_cluster" "challengeapp_cluster" {
  name = "challengeapp_cluster" # Naming the cluster
}

# We configure the service and updatedb task definitions here. The service task definition will be used by the 
# service definition later but the updatedb task definition will be triggered manually to initialise DB.

resource "aws_ecs_task_definition" "challengeapp_service_task" {
  family                    = "challengeapp_service_task"
  requires_compatibilities  = ["FARGATE"] # Use Fargate for simplicity and cost savings
  network_mode              = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  cpu                       = 256
  memory                    = 512
  container_definitions     = jsonencode([
    {
      name         = "challengeapp_service_task"
      image        = "servian/techchallengeapp:latest"
      command      = ["serve"]
      environment  = [
          {"name": "VTT_DBHOST", "value": "${aws_db_instance.challengeappdb.address}"},
          {"name": "VTT_DBPORT", "value": "${tostring(var.dbport)}"},
          {"name": "VTT_DBUSER", "value": "${var.db_username}"},
          {"name": "VTT_DBPASSWORD", "value": "${var.db_password}"}
      ]
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "challengeapp_updatedb_task" {
  family                    = "challengeapp_updatedb_task"
  requires_compatibilities  = ["FARGATE"] # Use Fargate for simplicity and cost savings
  network_mode              = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  cpu                       = 256
  memory                    = 512
  container_definitions     = jsonencode([
    {
      name         = "challengeapp_updatedb_task"
      image        = "servian/techchallengeapp:latest"
      command      = ["updatedb", "-s"]
      environment  = [
          {"name": "VTT_DBHOST", "value": "${aws_db_instance.challengeappdb.address}"},
          {"name": "VTT_DBPORT", "value": "${tostring(var.dbport)}"},
          {"name": "VTT_DBUSER", "value": "${var.db_username}"},
          {"name": "VTT_DBPASSWORD", "value": "${var.db_password}"}
      ]
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "application_load_balancer" {
  name               = "challengeapp_lb"
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # Referencing the default VPC
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our tagrte group
  }
}

resource "aws_ecs_service" "challengeapp_service" {
  name            = "challengeapp_service"
  cluster         = "${aws_ecs_cluster.challengeapp_cluster.id}"
  task_definition = "${aws_ecs_task_definition.challengeapp_service_task.arn}"
  launch_type     = "FARGATE"
  desired_count   = 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.challengeapp_service_task.family}"
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
