# Some outputs to help us manually trigger the updatedb task later
output "subnetid" {
  description = "subnet a id"
  value       = aws_default_subnet.default_subnet_a.id
}
output "securitygroupid" {
  description = "service security group id"
  value       = aws_security_group.service_security_group.id
}
output "dnsname" {
  description = "dns name to access the application at"
  value       = aws_alb.application_load_balancer.dns_name
}