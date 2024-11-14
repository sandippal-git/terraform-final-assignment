output "vm-public-ip" {
  value = data.aws_instance.my-instance.public_ip
}

output "vpcid" {
  value = module.vpc.vpc_id
}

output "vpccidr" {
  value = data.aws_vpc.my-vpc.cidr_block
}

