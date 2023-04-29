# terraformec2-backup
Terraform Repo for backup policies with ec2 


Creates an S3 bucket to store backup files and defines a lifecycle policy that moves backup files to Glacier storage class after 30 days and filters backups that are 100 MB or larger.
Uploads a backup file to the S3 bucket and tags it with the "backup-size" tag key set to "large".
Keeps a copy of the largest backup file and uploads it to the same S3 bucket.
Configures a Glacier vault to store backup files and uploads the backup file and its copy to the Glacier vault with the "GLACIER" storage class. It also outputs a list of backup files that are more than 100 MB in size.
