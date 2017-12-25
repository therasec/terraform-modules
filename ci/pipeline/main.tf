provider aws {
  profile = "${var.provider_profile}"
  region  = "us-east-1"
}

resource "aws_codebuild_project" "tffmt" {
  name          = "${var.name}-terraform-fmt"
  description   = "Checks if ${var.name}'s terraform code is formatted"
  build_timeout = "5"

  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.code_build_image}"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TERRAFORM_DOWNLOAD_URL"
      "value" = "${var.terraform_download_url}"
    }

    environment_variable {
      "name"  = "TF_IN_AUTOMATION"
      "value" = "True"
    }

    environment_variable {
      "name"  = "MODULE_PATH"
      "value" = "tf_security_groups/sg_ssh"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ci/buildspec-terraform-fmt.yml"
  }
}

resource "aws_codebuild_project" "terrascan" {
  name          = "${var.name}-terrascan"
  description   = "Runs terrascan against ${var.name}"
  build_timeout = "5"

  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.code_build_image}"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TERRAFORM_DOWNLOAD_URL"
      "value" = "${var.terraform_download_url}"
    }

    environment_variable {
      "name"  = "MODULE_PATH"
      "value" = "tf_security_groups/sg_ssh"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ci/buildspec-terrascan.yml"
  }
}

resource "aws_codebuild_project" "tfplan" {
  name          = "${var.name}-terraform-plan"
  description   = "Runs terraform plan for ${var.name}"
  build_timeout = "10"

  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.code_build_image}"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TERRAFORM_DOWNLOAD_URL"
      "value" = "${var.terraform_download_url}"
    }

    environment_variable {
      "name"  = "MODULE_PATH"
      "value" = "tf_security_groups/sg_ssh"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ci/buildspec-terraform-plan.yml"
  }
}

resource "aws_codebuild_project" "tfapply" {
  name          = "${var.name}-terraform-apply"
  description   = "Runs terraform apply for ${var.name}"
  build_timeout = "10"

  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.code_build_image}"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TERRAFORM_DOWNLOAD_URL"
      "value" = "${var.terraform_download_url}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-terraform-apply.yml"
  }
}

resource "aws_codepipeline" "pipeline" {
  name = "${var.name}-terraform-pipeline"

  # FIXME
  # role_arn = "${aws_iam_role.codepipeline_execution_role.arn}"
  role_arn = "arn:aws:iam::445730574438:role/managed/AMI-Builder-Blogpost-PipelineExecutionRole-KWXEH5ZNKNAV"

  artifact_store {
    # FIXME
    # location = "${aws_s3_bucket.build_artifacts.bucket}"
    location = "terraform-modules-artifacts"

    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "modules-repo"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_zip"]

      configuration {
        Owner  = "${var.github_repo_owner}"
        Repo   = "${var.github_repo_name}"
        Branch = "${var.github_repo_branch}"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "terraform-fmt"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_zip"]
      output_artifacts = ["terraform_fmt"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.tffmt.name}"
      }
    }

    action {
      name             = "terrascan"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_zip"]
      output_artifacts = ["terrascan"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.terrascan.name}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "terraform-plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_zip"]
      output_artifacts = ["terraform_plan"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.tfplan.name}"
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "request-approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration {
        NotificationArn = "${aws_sns_topic.validation.arn}"
      }
    }
  }

  stage {
    name = "Provision"

    action {
      name             = "terraform-apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["terraform_plan"]
      output_artifacts = ["terraform_apply"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.tfapply.name}"
      }
    }
  }
}
