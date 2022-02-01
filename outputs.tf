# Some outputs to help us manually trigger the updatedb task later
output "subnetaid" {
  description = "subnet a id"
  value       = aws_default_subnet.default_subnet_a.id
}
output "securitygroupid" {
  description = "service security group id"
  value       = aws_security_group.service_security_group.id
}