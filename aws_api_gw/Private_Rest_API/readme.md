#to deploy Private API Gateway

    cd ./Private_Rest_API
    terraform init
    terraform plan --var-file=./env/dev.tfvars --target=module.import_api
    terraform apply --var-file=./env/dev.tfvars --target=module.import_api
    terraform plan --var-file=./env/dev.tfvars --target=module.api_operations
    terraform apply --var-file=./env/dev.tfvars --target=module.api_operations
