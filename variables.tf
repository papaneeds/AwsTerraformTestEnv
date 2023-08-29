variable "num_wintak_machines" {
   type = number
   default = 2 
}

variable "num_vpcs" {
    type = number
    default = 2
}

# This is the IP address of the external machine used to access the AWS instance
variable "aws_access_ip" {
    type = string
    # default = "104.247.242.154"
}