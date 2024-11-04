location = "centralIndia"
prefix = "test"
environment = "test"
resourceFunction = "apim"

tags = {
  environment = "Development",
  createdBy = "Terraform"
}
apim = {
  sku_name = "Developer"
  sku_capacity = "1"
  publisherName = "Sri"
  publisherEmail = "admin@srisri.xyz"
}
apimSku = "Developer"
apimSkuCapacity = 1
apimPublisherName = "srisri"
apimPublisherEmail = "sagarpranith@outlook.in"

virtualnetwork = {
    NetworkAddress = "10.0.0.0/8"
    gatewaySubnetAddress = "10.0.0.0/24"
    subnetAddress = "10.0.1.0/24"
    backendSubnetAddress = "10.0.2.0/24"
  }
  
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
    password = "Azure@2024"
}

subscription = {
    subscriptionName = "Internal"
}
subscription_id = "549e90a6-40ca-4c76-8aa8-8f6ea2a287f4"

backend = {
  username = "adminuser"
  password = "Cloud@20242024"
}
