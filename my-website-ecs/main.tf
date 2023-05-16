locals {
  region             = var.region
  project_namee      = var.my_project_name
  environment        = var.enviroment
  profile            = "default"
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
    source           = "../modules/security groups"
    project_name     = var.my_project_name
    environment      = var.enviroment
    vpc_id           = module.vpc.vpc_id
    ssh_ip           = var.ssh_ip  
  }
  # launch rds instance
module "rds" {
  source                       = "../modules/rds"
  project_name                 = var.my_project_name
  environment                  = var.environment
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  database_snapshot_identifier = var.database_snapshot_identifier
  database_instance_class      = var.database_instance_class
  availability_zone_1          = module.vpc.availability_zone_1
  database_instance_identifier = var.database_instance_identifier
  multi_az_deployment          = var.multi_az_deployment
  database_security_group_id   = module.security_group.database_security_group_id
}
    
 # request ssl certificate
module "ssl_certificate" {
  source            = "../modules/acm"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}   
 
  

  module "ecs-task-execution-role" {
    source          = "../modules/ecs-tasks-execution-role"
    my_project_name = module.vpc.my_project_name
  }

  module "acm" {
    source           = "../modules/acm"
    domain_name      = var.domain_name
    alternative_name = var.alternative_name
}

module "alb" {
  source                 = "../modules/alb"
  my_project_name        = module.vpc.my_project_name
  alb_security_group_id  = module.security_groups.alb_security_group_id
  public_subnet_az1_id   = module.vpc.public_subnet_az1_id
  public_subnet_az2_id   = module.vpc.public_subnet_az2_id
  target_type            = var.target_type
  vpc_id                 = module.vpc.vpc_id
  certificate_arn        = module.acm.certificate_arn
}
    
# create s3 bucket
module "s3_bucket" {
  source                  = "../modules/s3"
  my_project_name         = var.my_project_name
  env_file_bucket_name    = var.env_file_bucket_name
  env_file_name           = var.env_file_name
}    
  
# create ecs task execution role
module "ecs_task_execution_role" {
  source               = "../modules/iam-role"
  project_name         = var.my_project_name
  env_file_bucket_name = module.s3_bucket.env_file_bucket_name
  environment          = var.environment
}  
 
# create ecs cluster, task defination and service
module "ecs" {
  source                       = "../modules/ecs"
  project_name                 = var.my_project_name
  environment                  = var.environment
  ecs_task_execution_role_arn  = module.ecs_task_execution_role.ecs_task_execution_role_arn
  architecture                 = var.architecture
  container_image              = var.container_image
  env_file_bucket_name         = module.s3_bucket.env_file_bucket_name
  env_file_name                = module.s3_bucket.env_file_name
  region                       = var.region
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  app_server_security_group_id = module.security_group.app_server_security_group_id
  alb_target_group_arn         = module.application_load_balancer.alb_target_group_arn
}  
    
# create auto scaling group
module "ecs_asg" {
  source       = "../modules/asg-ecs"
  project_name = var.my_project_name
  environment  = var.environment
  ecs_service  = module.ecs.ecs_service
}

# create record set in route-53
module "route-53" {
  source                             = "../modules/route-53"
  domain_name                        = module.ssl_certificate.domain_name
  record_name                        = var.record_name
  application_load_balancer_dns_name = module.application_load_balancer.application_load_balancer_dns_name
  application_load_balancer_zone_id  = module.application_load_balancer.application_load_balancer_zone_id
}

# print the website url
output "website_url" {
  value = join("", ["https://", var.record_name, ".", var.domain_name])
}


    
    
    
