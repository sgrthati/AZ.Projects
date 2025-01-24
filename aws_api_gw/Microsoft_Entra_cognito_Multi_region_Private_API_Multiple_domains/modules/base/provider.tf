terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws,
        aws.secondary
      ]
    # azuread = {
    #   source = "hashicorp/azuread"
    #   configuration_aliases = [
    #     azuread
    #   ]
    # }
    }
  }
}