# -------------------------------------------------------------------------------------------------
# Code Build
# -------------------------------------------------------------------------------------------------

resource "aws_codebuild_project" "codebuild" {
  depends_on = [
    aws_ecr_repository.ecr_image_repo
  ]
  name         = "codebuild-${var.container_display_name_nts_webapp}-${var.container_source_repo_branch_nts_webapp}"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = var.build_project_source
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.ecr_image_repo.repository_url
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_display_name_nts_webapp
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.container_source_repo_name_nts_webapp
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

  }
  source {
    type = var.build_project_source
    #buildspec = "./templates/buildspec_${var.build_projects[count.index]}.yml"
  }
}

# -------------------------------------------------------------------------------------------------
# Code Pipeline
# -------------------------------------------------------------------------------------------------


resource "aws_s3_bucket" "artifact_bucket" {
  force_destroy = true
}



resource "aws_codestarconnections_connection" "github" {
  name          = "nginx-github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "pipeline" {
  depends_on = [
    aws_codebuild_project.codebuild,
  ]
  name     = "${var.container_display_name_nts_webapp}-${var.container_source_repo_branch_nts_webapp}-Pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }
  tags = {
    Project  = "nts"
    Pipeline = "workload"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.container_source_repo_name_nts_webapp
        BranchName       = var.container_source_repo_branch_nts_webapp
      }
    }
  }


  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      run_order        = 1
      configuration = {
        ProjectName = aws_codebuild_project.codebuild.id
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      version         = "1"
      provider        = "ECS"
      run_order       = 1
      input_artifacts = ["BuildOutput"]
      configuration = {
        ClusterName       = aws_ecs_cluster.nts_webapp.name
        ServiceName       = aws_ecs_service.nts_webapp.name
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "15"
      }
    }
  }
}


# -------------------------------------------------------------------------------------------------
# ECR
# -------------------------------------------------------------------------------------------------
output "instance_ip_addr" {
  value = aws_ecr_repository.ecr_image_repo.repository_url
}

resource "aws_ecr_repository" "ecr_image_repo" {
  name                 = var.container_display_name_nts_webapp
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  #  image_scanning_configuration {
  #    scan_on_push = true
  #  }
}




# -------------------------------------------------------------------------------------------------
# IAM
# -------------------------------------------------------------------------------------------------

# Codebuild role

resource "aws_iam_role" "codebuild_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  path               = "/"
}

resource "aws_iam_policy" "codebuild_policy" {
  description = "Policy to allow codebuild to execute build spec"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.artifact_bucket.arn}/*"
    },
    {
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:GetDownloadUrlForLayer",
        "ecr:CompleteLayerUpload"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.ecr_image_repo.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild-attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}



# Codepipeline role

resource "aws_iam_role" "codepipeline_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  path               = "/"
}

resource "aws_iam_policy" "codepipeline_policy" {
  description = "Policy to allow codepipeline to execute"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.artifact_bucket.arn}/*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetBucketVersioning"
      ],
      "Resource": "${aws_s3_bucket.artifact_bucket.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
         "kms:DescribeKey",
         "kms:GenerateDataKey*",
         "kms:Encrypt",
         "kms:ReEncrypt*",
         "kms:Decrypt"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "codestar-connections:GetConnection",
        "codestar-connections:UseConnection",
        "codeconnections:GetConnection",
        "codeconnections:UseConnection"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action" : [
        "codebuild:StartBuild", "codebuild:BatchGetBuilds",
        "iam:PassRole",
        "ecs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline-attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}


###################### Outputs


output "codepipeline_name" {
  value       = aws_codepipeline.pipeline.name
  description = "The Name of the CodePipeline"
}


output "github_connector_name" {
  value       = aws_codestarconnections_connection.github.name
  description = "The name of the CodePipeline Github Connector"
}
