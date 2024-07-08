# output "vm_username" {
#   value = module.ProjectX.admin_username
# }
output "vm_login" {
  value = [ for ip in module.ProjectX.vm_public_ip : "sudo ssh -i ${path.cwd}/keys/private_key ${module.ProjectX.admin_username}@${ip}"]
}