output "web_public_ip" {
  description = "Public IPv4 address of the web EC2 instance."
  value       = aws_instance.web.public_ip
}

output "web_instance_id" {
  description = "Instance ID of the web EC2 instance."
  value       = aws_instance.web.id
}

output "database_private_ip" {
  description = "Private IPv4 address of the MongoDB EC2 instance."
  value       = aws_instance.database.private_ip
}

output "database_instance_id" {
  description = "Instance ID of the MongoDB EC2 instance."
  value       = aws_instance.database.id
}