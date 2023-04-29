variable "instance_name" {}

variable "ebs_volume_size" {}

resource "aws_instance" "ec2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my_key"
  subnet_id     = "subnet-12345678"

  tags = {
    Name = var.instance_name
  }
}

resource "aws_ebs_volume" "ebs" {
  availability_zone = "us-east-1a"
  size              = var.ebs_volume_size
}

resource "aws_volume_attachment" "attachment" {
  device_name = "/dev/sdf"
  instance_id = aws_instance.ec2.id
  volume_id   = aws_ebs_volume.ebs.id
}
