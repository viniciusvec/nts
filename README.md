# nts

This code delivers AWS infrastructure for microservices using the technology stack below.

| IaC CI/CD (\*)   | Workload CI/CD (+) | Microservices Infra (+)       |
| ---------------- | ------------------ | ----------------------------- |
| GitHub           | GitHub             | AWS ALB                       |
| AWS CodePipeline | AWS CodePipeline   | AWS ECS + Fargate             |
| AWS CodeBuild    | AWS CodeBuild      | AWS RDS Cluster (aka. Aurora) |
| HCL Terraform    | Docker             |                               |
|                  | AWS ECR            |                               |
|                  | AWS CodeBuild      |                               |

Other services were used to complement the infrastructure such as: AWS KMS, AWS Secret Manager, AWS Networking (IAM, VPC, SN, SG, etc.).

\* Only if the Full End-to-end Deployment is used (see option 1).<br />
\+ Deployed regardless.

### Directory Structure

```shell
|-- LICENSE
|-- README.md
|-- buildspec.yaml      -> for CodeBuild
|-- main.tf             -> for Terraform
|-- variables.tf        -> for Terraform
|-- loadbalancing.tf    -> for Terraform
|-- computing.tf        -> for Terraform
|-- storage.tf          -> for Terraform
```

## Pre-Requisites

### Step 1 (Optional): New AWS sandbox account

Creating a new AWS account to hold this environment is highly recommended to make the clean-up steps easier and avoid Security problems.

### Step 2: Configure AWS CLI

See docs: https://docs.aws.amazon.com/cli/latest/reference/configure/#examples

### Step 3: Install Terraform

See docs: https://developer.hashicorp.com/terraform/install
<br /><br />

## Installation

This code can be deployed with two options:

1. Via a Infrastructure as Code (IaC) pipeline - _recommended_.
2. Directly from your device using this repo only.
   <br /><br />

```shell
    -- Option 1 --
1 IaC CI/CD
    -- Option 1 & 2 --
2 Workload CI/CD
3 Microservices Infra
```

## Option 1: Full End-to-end Deployment

_IaC CI/CD + Workload CI/CD + Microservices Infra_<br />

Deployment workflow:

1. Terraform runs and IaC Pipeline is set up.
2. Manual intervention for the [new github connection](console.aws.amazon.com/codesuite/settings/connections). Aftewards you have to instruct the "tf-validate-project-pipeline" Pipeline to re-run the failed stage.
3. IaC CodePipeline pulls nts project (this), validates and deploys Workload CI/CD + Microservices Infrastructure.
4. ECS Cluster (part of Microservices Infrastructure) will be empty of Tasks, until the Workload CI/CD processes the pulls nginx-buildspec and deploys the container into ECR.
5. Manual intervention for the new github connection. Aftewards you have to instruct the "nts_webapp-main-Pipeline" Pipeline to re-run the failed stage.
6. The "nts_webapp-main-Pipeline" will make the container available on ECR. ECS Cluster will then pull image from ECR and deploy the nts webapp task.
7. ECS will deploy the task and register it with ALB.
8. Webapp (nginx) should be available externally via ALB address

A ready-made code to deploy a IaC CI/CD was forked from AWS samples and has been modified for a number of reasons (see the README for details): from scratch: https://github.com/viniciusvec/aws-codepipeline-terraform-cicd-samples

### Step 1: Clone the IaC pipeline repository.

Using git cli:

```shell
gh repo clone viniciusvec/aws-codepipeline-terraform-cicd-samples
```

or for other options read: [GitHub Docs - Cloning a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)

### Step 2: Initialize the directory. Run terraform init

```shell
terraform init
```

### Step 3: Run terraform plan and apply

```shell
terraform plan -out tf-plan
terraform apply tf-plan
```

### Step 4: Manually authorise the connector in AWS

AWS requires manual intervention to update the pending [new github connection](console.aws.amazon.com/codesuite/settings/connections).
This is needed for the CodePipeline source stage to be able to pull the web app microservice code from the configured repos.

Follow the instructions: https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-update.html

Then, [instruct the "tf-validate-project-pipeline" Pipeline](console.aws.amazon.com/codesuite/codepipeline/pipelines/tf-validate-project-pipeline/view) to retry the failed stage.

### Step 5: Verify that CodePipeline is running

This should unclog the pipeline - check [CodePipeline](https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines?region=eu-west-2).
If needed, re-run the IaC pipeline first stage.

### Step 6: Manually authorise the connector in AWS

Once again, manual intervention is needed to update the pending connection to github.

- This is to let CodePipeline source stage to be able to pull terraform code from the configured repos.

- ! notice that terraform builds this connector very early so if this is done right after the previous manual intervention it may not need to re-run the failed stage on the "nts_webapp-main-Pipeline" Pipeline.

Follow the instructions: https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-update.html

Then, [instruct the "nts_webapp-main-Pipeline" Pipeline](console.aws.amazon.com/codesuite/codepipeline/pipelines/nts_webapp-main-Pipeline/view) to retry the failed stage.

### Step 7: Validate

Check with the command below the running EIPs associated with ALBs.

```shell
aws elbv2 describe-load-balancers --names "alb" --query "LoadBalancers[0].DNSName" --output json
```

_\* note that due to deployment workflow it takes 10-20 minutes for the the IaC components to set up, build the infrastructure, build container, deploy the ECS task and register with the ALB._
<br />

## Option 2: CI/CD + Microservices Infra only

_Workload CI/CD + Microservices Infra_<br />

Deployment workflow:

- Terraform runs and deploys Workload CI/CD + Microservices Infrastructure.
- ECS Cluster (part of Microservices Infrastructure) will be empty of Tasks, until the Workload CI/CD processes the pulls nginx-buildspec and deploys the container into ECR.
- ECS Cluster will then pull image from ECR and deploy the nts webapp task.
- ECS will deploy the task and register it with ALB.
- Webapp (nginx) should be available externally via ALB address

### Step 1: Clone this repository.

Using git cli:

```shell
gh repo clone gh repo clone viniciusvec/nts
```

or for other options read: [GitHub Docs - Cloning a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
<br /><br />

### Step 2: Run terraform plan and apply

```shell
terraform plan -out tf-plan
terraform apply tf-plan
```

### Step 3: Validate

Check the output from Terraform with the ALB URL.
_\* note that due to deployment workflow it takes 5-10 minutes for the build the infrastructure to set up, build container, deploy the ECS task and register with the ALB._
<br /><br />

# Clean-up steps

#### Run terraform destroy

Recommended - simply delete the AWS account created for this.

Otherwise:
Destroy using terraform.

```shell
terraform destroy -auto-approve
```

<br /><br />

## Outstanding work and Security notes

Some of due dilligence and improvement changes was not carried out to produce necessary features that fits in the time frame - prioritising working code over those.<br />

For Security reasons, do not use this code for production until dilligent review.<br />

To list a few:

- General code housekeeping: variables, modules, outputs, dependencies, etc..
- Implement VPC enpoints for AWS services to be able to block all egress from private subnet.
- ALB certificate termination and use of AWS Certificate Manager.
- Finetuning of IAM roles for CodePipeline
- The container deploy is simply nginx. For this reason, once other applications are selected, SG groups have to be adjusted.
- Infrastructure to support microservices such as SQS or EventBridge was provisioned.
- Customer-managed use of KMS keys and Secret Manager secrets - AWS-managed used instead.
- This could be be replaced if there are requirements: ECS -> EKS, ALB -> API Gateway, Fargate -> customer provisioned EC2, etc.
- Create workload that actually uses RDS.
- Implementation of Cloudtrail or other monitoring.
