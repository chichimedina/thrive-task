name = "thrive"

eks_version = "1.32"

environment = "dev"

aws_user = "cacaotech-admin"

vpc_cidr = "10.100.0.0/20"

public_subnets_cidr = [
   "10.100.1.0/24",
   "10.100.2.0/24",
   "10.100.3.0/24"
]

private_subnets_cidr = [
   "10.100.11.0/24",
   "10.100.12.0/24",
   "10.100.13.0/24"
]

availability_zones = [
   "us-east-2a",
   "us-east-2b",
   "us-east-2c"
]

eks_addon_repo_number = "602401143452"

tags = <<-EOF
{
  "ProjectCode": "thrive-tech",
  "Managed-By": "terraform"
}
EOF
