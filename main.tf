provider "aws" {
  region = "us-east-1"
}

# Define a variable for the instance names
variable "instance_names" {
  type    = set(string)
  default = ["dev", "stage", "prod"]
}

# Create EC2 instances and attach EBS volumes
module "ec2" {
  for_each = { for name in var.instance_names : name => name }

  source = "./ec2"

  instance_name = each.value
  ebs_volume_size = {
    "dev"   = 20
    "stage" = 40
    "prod"  = 200
  }
}

# Create backup policies with different schedules
module "backup" {
  for_each = { for name in var.instance_names : name => name }

  source = "./backup"

  instance_id = module.ec2[each.value].instance_id

  backup_schedule = {
    "dev"   = "cron(0 0 */15 * ? *)" # Backup every 15 days
    "stage" = "cron(0 0 */10 * ? *)" # Backup every 10 days
    "prod"  = "cron(0 0 * * ? *)"   # Backup every day
  }
}
