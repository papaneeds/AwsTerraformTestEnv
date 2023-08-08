variable "host_os" {
    type = string
    default = "windows"
}

# This is the IP address of the external machine used to access the AWS instance
variable "aws_access_ip" {
    type = string
    # default = "104.247.242.154"
}