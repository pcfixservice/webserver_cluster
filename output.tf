output "alb_dns_name" {
  value       = aws_lb.asg_cluster_lb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.asg_cluster.name
  description = "The name of the Auto Scaling Group"
}


#############################################################################
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}

#export the ID of the aws_security_group as an output variable

