variable "vpc_id" {}

resource "aws_security_group" "sg" {
  name        = "ssh"
  description = "SSH access"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = "22"
    to_port   = "22"
    protocol  = "tcp"

    #cidr_blocks = ["172.31.0.0/16"]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "id" {
  value = "${aws_security_group.sg.id}"
}
