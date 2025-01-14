resource "aws_codebuild_project" "ci_comparism" {
  name          = "CI-comparism"
  description   = "Codebuild project for CI comparism docker images CI/CD pipeline"
  build_timeout = "5"
  service_role  = aws_iam_role.this.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "DOCKER_USER"
      value = var.DOCKER_USER

    }

    environment_variable {
      name  = "DOCKER_PASS"
      value = var.DOCKER_PASS

    }
  }


  # Make sure the group name and stream names exist
  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-log-group"
      stream_name = "log-stream"
    }

  }

  source {
    type                = "CODEPIPELINE"
    report_build_status = true
    buildspec           = file("../buildspec.yml")
    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "master"

  # If you are using private subnets for CodeBuild then only use VPC configureation. In that case VPC must have NAT gateway.
  # If you are simply using all public network then DONT'T use VPC config.  
  # vpc_config {
  #   vpc_id  = aws_vpc.elb_vpc.id
  #   subnets = [aws_subnet.elb_subnet.id]
  #   security_group_ids = [aws_security_group.allow_all.id]
  # }

}
