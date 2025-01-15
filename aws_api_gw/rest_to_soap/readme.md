#to deploy Private API Gateway

    cd aws_api_gw/Multi_region_Private_API/
    terraform init
    terraform plan --var-file=./env/dev.tfvars --target=module.import_api
    terraform apply --var-file=./env/dev.tfvars --target=module.import_api --auto-approve
    terraform plan --var-file=./env/dev.tfvars --target=module.api_operations
    terraform apply --var-file=./env/dev.tfvars --target=module.api_operations --auto-approve

#to clean up

    terraform destroy --var-file=./env/dev.tfvars --auto-approve