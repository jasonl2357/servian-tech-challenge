# TechChallengeApp deployment

This is Jason Lee's submission for the Service tech challenge app assessment.

## Repository structure

``` sh
.
├── main.tf        # Contains configuration for the bulk of the infrastructure including the applications to be deployed
├── db.tf          # Contains specific configurations for the databases
├── variables.tf   # Contains user defined variables
├── outputs.tf     # Contains outputs which are needed for some deployment steps
└── README.md      # This document
```

## Prerequisites

Before attempting to deploy this app, ensure that you have a machine with the following prerequites met:

- Internet connection to access AWS and GitHub.
- Git installed.
- Terraform version v1.1.4 or higher installed.
- AWS CLI 2.4.15 or higher installed.
- AWS CLI configured with a valid AWS account with rights to provision resources.

## Limitations and future improvements

Due to the limited time available before submitting this assessment, not all best practices were followed in the interest of time. These are detailed below.

- All the resources including database are created in the default VPC. These should be segregated further in the future in the interest of security.
- Autoscaling for the service containers should be added in the future to allow dynamic scaling of resources.

## Deployment instructions

To deploy the application follow the following steps

1. Ensure the Prerequisites have been met
2. Clone the git repository to the machine using:
`git clone https://github.com/jasonl2357/servian-tech-challenge.git`
3. Move into the cloned directory then run the following command to initialise the terraform directory:
`terraform init`
4. Edit variables.tf to edit which AWS region you want to deploy into then run:
`terraform apply`
5. This will prompt for the DB user and password to be used to provision resources. Set your own credentials here and keep them in a safe place.
6. Once the deployment is done, you will get some outputs that look similar to below note these down for the following steps:
``` sh
dnsname = "test-lb-tf-761000961.ap-southeast-2.elb.amazonaws.com"
securitygroupid = "sg-06f7898adbbc6b64c"
subnetid = "subnet-21383068"
```
7. If this is the first time this has been provisioned and the database is empty, run the following command to populate the database. Replace the subnets and securityGroups values with the output from above. If the database is already populated this step can be skipped.
`aws ecs run-task --task-definition challengeapp_updatedb_task --network-configuration "awsvpcConfiguration={subnets=["subnet-21383068"],securityGroups=["sg-06f7898adbbc6b64c"],assignPublicIp='ENABLED'}" --cluster challengeapp-cluster --launch-type="FARGATE"`
8. You can now access the deployed application on the dnsname output from above.

