resource "aws_ebs_volume" "paper_ebs" {
  availability_zone = var.availability_zone
  size              = var.paper_ebs_size
  type              = "gp3"

  tags = {
    Name = "${var.project_name}-paper-ebs"
  }
}

resource "aws_ebs_volume" "velocity_ebs" {
  availability_zone = var.availability_zone
  size              = var.velocity_ebs_size
  type              = "gp3"

  tags = {
    Name = "${var.project_name}-velocity-ebs"
  }
}