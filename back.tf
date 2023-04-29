variable "instance_id" {}

variable "backup_schedule" {}

resource "aws_backup_plan" "backup" {
  name       = "my_backup_plan_${var.instance_id}"
  rule_count = 1

  rule {
    rule_name         = "my_backup_rule_${var.instance_id}"
    target_vault_name = "my_backup_vault"
    schedule          = var.backup_schedule

    lifecycle {
      delete_after_days = 90
    }

    start_window_minutes = 60

    recovery_point_tags = {
      environment = var.instance_id
    }
  }
}
