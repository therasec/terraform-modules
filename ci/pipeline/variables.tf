variable "provider_profile" {
  description = "AWS credentials profile"
}

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
  default     = "master"
}

variable "code_build_image" {
  description = "Docker image to use for CodeBuild container - Use http://amzn.to/2mjCI91 for reference"
  default     = "aws/codebuild/ubuntu-base:14.04"
}

variable "terraform_download_url" {
  description = "URL for terraform version to be used for builds"
  default     = "https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip"
}
