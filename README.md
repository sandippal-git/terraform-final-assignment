# terraform-final-assignment
terraform-final-assignment

# commands used for testing
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars" -auto-approve
terraform destroy-auto-approve

# Problem faced
Output data retrive from the instances. After second run without any changes apply it's retrive public IP.

