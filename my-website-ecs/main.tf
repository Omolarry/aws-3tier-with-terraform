#configure aws provider
provider "aws" {
  region     = var.region
  profile    = "default"
}

#create VPC
module "vpc" {
    source                          = "../modules/vpc"
    region                          = var.region
    project_name                    = var.my_project_name
    vpc_cidr                        = var.vpc_cidr
    public_subnet_az1_cidr          = var.public_subnet_az1_cidr
    public_subnet_az2_cidr          = var.public_subnet_az2_cidr
    private_app_subnet_az1_cidr     = var.private_app_subnet_az1_cidr
    private_app_subnet_az2_cidr     = var.private_app_subnet_az2_cidr
    private_data_subnet_az1_cidr    = var.private_data_subnet_az1_cidr
    private_data_subnet_az2_cidr    = var.private_data_subnet_az2_cidr
}

#create NAT gateway
  module "nat_gateway" {
    source                          = "../modules/nat-gateway"
    public_subnet_az1_id            = module.vpc.public_subnet_az1_id
    internet_gateway                = module.vpc.internet_gateway.id
    public_subnet_az2_id            = module.vpc.public_subnet_az2_id
    vpc_id                          = module.vpc.vpc_id
    private_app_subnet_az1_id       = module.vpc.private_app_subnet_az1_id
    private_data_subnet_az1_id      = module.vpc.private_data_subnet_az1_id
    private_app_subnet_az2_id       = module.vpc.private_app_subnet_az2_id
    private_data_subnet_az2_id      = module.vpc.private_data_subnet_az2_id

  }

  #security group
  module "security_group" {
    source = "../modules/security groups"
    vpc_id = module.vpc.vpc_id
  }
  
 /* module "ec2_instance" {
  source = "../modules/ec2-instance"

  ami_id              = ami-1234567890abcdef0
  instance_type       = t2.micro
  subnet_id           = module.vpc.public_subnet_az1_id
  security_group_ids  = module.security_group
  key_name            = my_keypair
}
*/