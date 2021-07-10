tcb-azure-m4

BootCamp Azure – Module 4

Deploy VPN GATEWAY and AZURE FIREWALL

Requeriments and Instructions:

- Run commands in a linux host (needs terraform);
- Create azure user principal: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
- Set Azure parameters.tf and tfvar.tf
- Generate your ssh key pair (use key.pem and key.pub names for script compatibility);
- terraform init -> terraform validate -> terraform plan -out plan -> terraform apply plan;
- Deployment takes more than 45 minutes. Let´s take coffee
- Install clientcert-201022-172846.pfx in Windows 10 with default options;
- After VPN-GW deployment ends, donwload VPN client and install in Windows 10 and access de VPN;
- Access de WebServer with a browser and client machine with RDP client (user and pass in main.tf file).