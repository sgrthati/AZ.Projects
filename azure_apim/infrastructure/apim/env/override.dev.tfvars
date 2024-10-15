location = "centralIndia"
prefix = "test"
environment = "dev"
resourceFunction = "apim"

tags = {
  environment = "Development",
  createdBy = "Terraform"
}

apimSku = "Developer"
apimSkuCapacity = 1
apimPublisherName = "srisri"
apimPublisherEmail = "sagarpranith@outlook.in"

product = {
    productId = "srisri"
    productName = "srisri"
    subscriptionRequired = true
    subscriptionsLimit = 5
    approvalRequired = true
    published = true
}

user = {
    firstName = "sagar",
    email = "sagarpranith@gmail.com"
}

subscription = {
    subscriptionName = "Internal"
}
subscription_id = "549e90a6-40ca-4c76-8aa8-8f6ea2a287f4"