#Azure Location
variable "AZURE_LOCATION" {
    type = string
    default = "eastus"
}

#RG Name
variable "RG_NAME" {
    type = string
    default = "TCB-AZ-M4"
}

#VNET CIDR
variable "VNET_CIDR" {
    type = string
    default = "10.0.0.0/16"
}

#SUBNET_INTERNAL_CIDR
variable "SUBNET_INTERNAL_CIDR" {
    type = string
    default = "10.0.1.0/24"
}

#SUBNET_VPNGW_CIDR
variable "SUBNET_VPNDW_CIDR" {
    type = string
    default = "10.0.10.0/24"
}

#SUBNET_FW_CIDR
variable "SUBNET_FW_CIDR" {
    type = string
    default = "10.0.20.0/26"
}

#VPN_CLIENT_ADDRESS
variable "VPN_CLIENT_ADDRESS" {
    type = string
    default = "172.16.0.0/24"
}

#Subscription ID
variable "SUB_ID" {
    type = string
    default = ""
}

#Principal Client ID
variable "CLI_ID" {
    type = string
    default = ""
}

#Principal Client SECRET
variable "CLI_SECRET" {
    type = string
    default = ""
} 

#Tenant ID  
variable "TEN_ID" {
    type = string
    default = ""
} 