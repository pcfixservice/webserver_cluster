#these are input variables so any other env can use them, this help to avoid to harcoded the values
#The input variables are the API of the module, controlling how it will behave in different environments. 
#This example uses different names in different environments,

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
 description = "The path for the database's remote state in S3"
 type = string
}

#in staging, you might want to run a small web server cluster to save money, but in production, 
#you might want to run a larger cluster to handle lots of traffic.

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "image_id" {
  description = "the AMI image id of the image for the instance"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "server_port" {
  description = "server port 80"
  type 	      = string
}

variable "alb_name" {
  description = "Application Load Balacer name"
  type 	      = string
}

variable "instance_security_group_name" {
  description = "Security group name"
  type 	      = string
}
