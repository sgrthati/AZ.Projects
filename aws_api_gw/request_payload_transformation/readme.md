#to deploy Private API Gateway

    cd aws_api_gw/Transofrmation/
    terraform init
    terraform plan --var-file=./env/dev.tfvars --target=module.import_api
    terraform apply --var-file=./env/dev.tfvars --target=module.import_api --auto-approve
    terraform plan --var-file=./env/dev.tfvars --target=module.api_operations
    terraform apply --var-file=./env/dev.tfvars --target=module.api_operations --auto-approve

#for POST method
{
    "userId": 200,
    "id": 200,
    "title": "senthil",
    "body": "senthil"
}

#to clean up

    terraform destroy --var-file=./env/dev.tfvars --auto-approve
