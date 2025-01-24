resource "aws_cognito_user_pool" "pool" {
  name = var.cognito.name
  password_policy {
    minimum_length = 8
    require_lowercase = false
    require_uppercase = false
    require_numbers   = false
    require_symbols   = false
  }
}
resource "aws_cognito_user_pool_client" "pool_client" {
  name                                 = "pool-client"
  generate_secret = true
  user_pool_id                         = aws_cognito_user_pool.pool.id
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  callback_urls                        = ["https://example.com"]
  prevent_user_existence_errors        = "ENABLED"
}
resource "aws_cognito_user" "yt_user" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = var.cognito.user1
  password     = var.cognito.password
}