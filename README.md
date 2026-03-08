# MasterClassParis - A Beginner's Guide to Terraform & Cloud Infrastructure

Welcome! 👋 This project is a **hands-on learning resource** for understanding how to build cloud infrastructure using **Terraform** and **Google Cloud Platform (GCP)** in an automated way through **CI/CD** with **GitLab**.

---

## 📚 What is This Project About?

This is an **Infrastructure as Code (IaC)** project that teaches you how to:

1. **Define cloud infrastructure with code** (using Terraform)
2. **Deploy it automatically** to Google Cloud Platform
3. **Manage it through GitLab** (a version control and CI/CD system)
4. **Build a data processing platform** with multiple Google Cloud services

Think of it this way: Instead of clicking buttons in the Google Cloud Console to create resources, **you write code to describe what you want**, and Terraform creates it for you. This is automation and reproducibility in action!

---

## 🏗️ Project Structure Explained

```
terraform_project/
├── envs/               # Environment configurations (dev, staging, prod)
│   └── dev/           # Development environment setup
├── modules/           # Reusable building blocks
│   ├── artifact_registry/   # Docker image storage
│   ├── bigquery/           # Data warehouse
│   ├── gcs/               # Cloud storage (file storage)
│   ├── iam/               # Security & permissions
│   └── pubsub/            # Message queue service
└── scripts/           # Setup and automation scripts
```

### What Each Folder Does:

**`envs/dev/`** - The Development Environment
- This is where you define what infrastructure you want in your development environment
- Think of it as the "recipe" that Terraform will follow to build your cloud setup
- Files here reference the modules below to say "I want these services with these settings"

**`modules/`** - The Building Blocks
- Each module is a reusable piece of infrastructure code
- **Artifact Registry**: A private container repository (like Docker Hub) to store your application images
- **BigQuery**: A massive data warehouse for analyzing big data
- **GCS (Cloud Storage)**: Simple file storage in the cloud (like Google Drive for computers)
- **IAM**: Identity & Access Management - controls who can do what
- **Pub/Sub**: A messaging service for applications to communicate with each other

**`scripts/`** - The Setup Helpers
- Scripts that run in the beginning to set up permissions and credentials
- `masterclass-sa-gitlab.sh` - Creates a service account (a special "bot" account) that GitLab uses to deploy resources

---

## 🎯 What Does This Infrastructure Do?

This project sets up a **complete data pipeline infrastructure** on Google Cloud that includes:

### 1. **Docker Container Registry** (Artifact Registry)
- Stores your application in container format (Docker)
- Like a private app store for your code
- When you push code to GitLab, it gets converted to a container and stored here

### 2. **File Storage** (Cloud Storage - GCS)
- Stores raw data files
- Like a secure hard drive in the cloud
- Scalable to store terabytes of data

### 3. **Data Warehouse** (BigQuery)
- Analyzes and queries data
- Perfect for running analytics on large datasets
- Like a super-fast Excel for big data

### 4. **Message Queue** (Pub/Sub)
- Applications publish messages to a topic
- Other applications subscribe and receive those messages
- Like a mailbox system for your apps to send data to each other

### 5. **Security Setup** (IAM)
- Creates a Service Account (a special automated user)
- Gives it specific permissions to create and manage these resources
- Follows the principle of least privilege (gives only necessary permissions)

---

## 🔄 How Does the Workflow Work?

Here's the **step-by-step flow** of what happens:

```
1. Developer writes Terraform code (describes infrastructure)
   ↓
2. Developer pushes code to GitLab (git push)
   ↓
3. GitLab CI/CD triggers automatically
   ↓
4. CI/CD pipeline runs `terraform plan` (shows what will be created)
   ↓
5. CI/CD pipeline runs `terraform apply` (actually creates resources on GCP)
   ↓
6. All resources appear on Google Cloud Platform automatically!
```

**Without this automation**, you would have to:
- Log into Google Cloud Console
- Click through dozens of menus
- Manually create each resource
- Type the same commands again and again
- Risk making mistakes
- Forget what you created

**With Terraform + GitLab CI/CD**, it's all automatic and reproducible!

---

## 📋 Key Concepts for Beginners

### **Terraform**
- A tool that lets you write infrastructure in code (like writing a recipe)
- Version controlled (tracks changes over time)
- Reusable (same code works for different environments)

### **Infrastructure as Code (IaC)**
- Instead of manually creating resources, you describe them in code
- Benefits:
  - **Reproducible**: Run the same code, get the same infrastructure
  - **Trackable**: Git tracks who changed what and when
  - **Reversible**: Easy to delete and recreate
  - **Scalable**: Copy code to create multiple environments

### **Modules**
- Reusable blocks of Terraform code
- Instead of writing the same resource configuration 10 times, write it once in a module
- Then use (call) that module whenever you need it

### **CI/CD (Continuous Integration / Continuous Deployment)**
- **Continuous Integration**: Automatically test code when pushed
- **Continuous Deployment**: Automatically deploy code when tests pass
- In this project: When you push code, it automatically deploys to GCP

### **Service Account**
- A special "bot" account that can perform actions on Google Cloud
- Used by GitLab to authenticate and deploy without storing passwords
- Similar to API keys but more secure

### **Environments**
- Different setups for different stages (dev, staging, production)
- **Dev**: For testing new features
- **Staging**: A copy of production to test before going live
- **Prod**: The real, live system

---

## 🚀 Getting Started

### Prerequisites
You'll need:
1. A Google Cloud Platform account with billing enabled
2. Terraform installed on your computer
3. Google Cloud CLI (`gcloud`) installed
4. Git installed
5. A GitLab account or access to a GitLab project

### Step 1: Set Up Credentials
GitLab needs permission to create resources on your GCP account. Run:

```bash
cd terraform_project/scripts
bash masterclass-sa-gitlab.sh
```

This script:
- Creates a special "service account" on GCP
- Gives it all necessary permissions
- This account will be used by GitLab to deploy

### Step 2: Plan Your Infrastructure
Before creating anything, see what Terraform will create:

```bash
cd terraform_project/envs/dev
terraform plan
```

This shows you exactly what will be created (like a dry run).

### Step 3: Apply Your Infrastructure
Actually create the resources:

```bash
terraform apply
```

Terraform will ask for confirmation, then create everything. After a few minutes, all resources will be live on GCP!

### Step 4: Verify on Google Cloud Console
Log into [Google Cloud Console](https://console.cloud.google.com) and you'll see:
- A Docker registry in Artifact Registry
- A storage bucket in Cloud Storage
- A dataset in BigQuery
- A topic in Pub/Sub

### Step 5: Clean Up (Optional)
When you're done experimenting, delete all resources:

```bash
terraform destroy
```

This prevents unnecessary charges!

---

## 📁 Inside the Dev Environment

The **`envs/dev/`** folder contains:

- **`main.tf`** - The main configuration that calls all modules
- **`variables.tf`** - Settings like project ID and region (make these match your GCP setup)
- **`providers.tf`** - Tells Terraform to use Google Cloud Platform
- **`backend.tf`** - Stores Terraform state (keeps track of what was created)

### Example: How `main.tf` Works

```terraform
module "storage" {
  source = "../../modules/gcs"
  bucket_name = "masterclass-bucket"
  region = var.region
}
```

This means: "Use the GCS module and create a bucket named `masterclass-bucket`"

---

## 🔐 Security Best Practices (Learn These!)

This project demonstrates important security practices:

1. **Service Accounts**: Never use your personal credentials
2. **IAM Roles**: Each account has only the permissions it needs
3. **Code Review**: Changes go through Git (trackable and reviewable)
4. **Infrastructure Versioning**: Track all changes like any software project

---

## 🎓 Learning Paths

### Path 1: Understand Terraform Basics
- Read each `.tf` file in `modules/`
- Understand what each resource does
- Modify variables and re-deploy to see changes

### Path 2: Understand GCP Services
- Look at what each module creates
- Log into Google Cloud Console and explore the resources
- Read GCP documentation for each service

### Path 3: Master CI/CD
- Look at the GitLab setup
- Understand how the pipeline automatically deploys
- Create your own pipeline configuration

### Path 4: Advanced Infrastructure
- Add more modules (Cloud Run, Cloud Functions, etc.)
- Create multiple environments (staging, production)
- Set up monitoring and alerts

---

## 📚 Helpful Resources

- **[GitLab CI/CD Detailed Guide](GITLAB_CI_GUIDE.md)** - Complete explanation of the pipeline (MUST READ!)
- **Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- **Google Cloud Platform**: https://cloud.google.com/docs
- **GitLab CI/CD**: https://docs.gitlab.com/ci/
- **Terraform Best Practices**: https://www.terraform.io/language
- **Infrastructure as Code Guide**: https://www.ibm.com/cloud/learn/infrastructure-as-code

---

## 🤔 Common Questions

**Q: Will this cost money?**
A: Yes, Google Cloud resources incur charges. You get a free trial first. Remember to run `terraform destroy` when done!

**Q: Can I use this for production?**
A: This is a starter template. For production, add:
- Backup and disaster recovery
- Better security (VPCs, firewalls)
- Monitoring and logging
- Multiple redundant instances

**Q: What if I make a mistake?**
A: That's the beauty of code! Just edit and re-deploy. Or destroy and rebuild.

**Q: Do I need to learn all of Terraform?**
A: No! Start with templates and examples (like this project), then gradually learn more.

---

## 💡 Next Steps

1. **Clone this repository** and explore the code
2. **Read through each module** to understand what resources are being created
3. **Modify the variables** in `envs/dev/variables.tf` to match your GCP project
4. **Run `terraform plan`** to see what will be created
5. **Run `terraform apply`** to actually create the resources
6. **Explore the resources** in Google Cloud Console
7. **Experiment!** Change settings and redeploy to learn

---

## 📝 Contributing

This is a masterclass project! Feel free to:
- Add more modules
- Create new environments
- Improve documentation
- Submit merge requests with your improvements

---

## 📧 Support

For questions or issues:
1. Check the terraform output for error messages
2. Read the Terraform/GCP documentation
3. Ask your instructor
4. Check GitLab issues

---

**Happy Learning! 🎉**

Remember: Infrastructure as Code is a powerful skill. Once you master this template, you'll be able to build and manage any cloud infrastructure automatically!
