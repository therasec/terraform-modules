variable "name" {
  description = "This name will be appended to all pipeline resources"
}

variable "github_repo_owner" {
  description = "GitHub Username or Org"
}

variable "github_repo_name" {
  description = "Name of the repository"
}

variable "github_repo_branch" {
  description = "Branch that pipeline will apply to"
  default = "master"
}

variable "code_build_image" {
  description = "Docker image to use for CodeBuild container - Use http://amzn.to/2mjCI91 for reference"
  default = "aws/codebuild/ubuntu-base:14.04"
}

variable "builder_vpc" {
  description = "VPC ID that AMI Builder will use to launch temporary resource"
}

variable "builder_public_subnet" {
  description = "Public Subnet ID that AMI Builder will use to launch temporary resource"
}

variable "notification_email_address" {
  description = "Email to receive new AMI ID created by AMI Builder"
}
