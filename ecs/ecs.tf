# Create ECS cluster
resource "aws_ecs_cluster" "main" {
    name = var.ecs_cluster_name
}

data "template_file" "app" {
    template = file("${var.template_file_path}")

    vars = {
        app_name       = var.app_name
        app_port       = var.app_port
        fargate_cpu    = var.fargate_cpu
        fargate_memory = var.fargate_memory
        app_image     = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.image_repo_name}:${var.image_tag}"
    }
}

# Create the task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-task-family"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.app.rendered
}

# Create Fargate service inside the cluster
resource "aws_ecs_service" "main" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
      security_groups  = [aws_security_group.ecs_tasks.id]
      subnets          = aws_subnet.private.*.id
      assign_public_ip = true
  }

  load_balancer {
      target_group_arn = aws_alb_target_group.app.id
      container_name   = var.app_name
      container_port   = var.app_port
  }
  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs-task-execution-role-policy-attachment]
}