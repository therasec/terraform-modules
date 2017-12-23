provider aws {
  # profile = "therasec-prod"
  region = "us-east-1"
}

module "sg" {
  source = "../"
  vpc_id = "vpc-14595772"
}

output "sg" {
  value = "${module.sg.id}"
}
