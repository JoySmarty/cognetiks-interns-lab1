resource "aws_ecs_cluster" "main" {
  name = "ecs-lab-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode ({
    Version   = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "cloud-lab-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "cloud-lab-container"
      image     = "528757789388.dkr.ecr.us-east-1.amazonaws.com/cloud-lab-app:v1.0.0"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]

      environment = [
        { name = "APP_NAME", value = "Cloud Lab Starter App" },
        { name = "INTERN_NAME", value = "Joy Imarah" },
        { name = "CLOUD_PLATFORM", value = "AWS" },
        { name = "ENVIRONMENT", value = "dev" },
        { name = "APP_VERSION", value = "v1.0.0" },
        { name = "APP_STATUS", value = "healthy" }
      ]
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "cloud-lab-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "cloud-lab-container"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.app_listener]
}
