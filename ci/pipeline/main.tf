provider aws {
  profile = "${var.provider_profile}"
  region  = "us-east-1"
}


resource "aws_codebuild_project" "fmt" {
  name         = "${var.name}-terraform-fmt"
  description  = "Checks if ${var.name}'s terraform code is formatted"
  build_timeout = "5"
  # FIXME
  # service_role = "${aws_iam_role.codebuild_role.arn}"
  service_role = "arn:aws:iam::445730574438:role/codebuild-terraform-modules"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.code_build_image}"
    type         = "LINUX_CONTAINER"

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
    type     = "CODEPIPELINE"
    buildspec = "ci/buildspec-terraform-fmt.yml"
  }
}


resource "aws_codepipeline" "pipeline" {
  name     = "${var.name}-terraform-pipeline"
  # FIXME
  # role_arn = "${aws_iam_role.codepipeline_execution_role.arn}"
  role_arn = "arn:aws:iam::445730574438:role/managed/AMI-Builder-Blogpost-PipelineExecutionRole-KWXEH5ZNKNAV"

  artifact_store {
    # FIXME
    # location = "${aws_s3_bucket.build_artifacts.bucket}"
    location = "terraform-modules-artifacts"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Terraform modules repo"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_zip"]
      run_order = 1

      configuration {
        Owner      = "${var.github_repo_owner}"
        Repo       = "${var.github_repo_name}"
        Branch     = "${var.github_branch}"
      }
    }
  }

  stage {
    name = "terraform fmt"

    action {
      name            = "fmt"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_zip"]
      output_artifacts = ["built_zip"]
      version         = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.fmt.name}"
      }
    }
  }
}
