# GitLab CI/CD Pipeline - Detailed Explanation

Welcome to a comprehensive guide on **GitLab CI/CD** in the MasterClassParis project! This document explains how the automation pipeline works, step-by-step, in a way that beginners can understand.

---

## 📖 Table of Contents

1. [What is CI/CD?](#what-is-cicd)
2. [How Our Pipeline Works](#how-our-pipeline-works)
3. [The `.gitlab-ci.yml` File Explained](#the-gitlab-ciyml-file-explained)
4. [Pipeline Stages in Detail](#pipeline-stages-in-detail)
5. [Authentication: OIDC & Workload Identity](#authentication-oidc--workload-identity)
6. [Environment Variables](#environment-variables)
7. [Running the Pipeline](#running-the-pipeline)
8. [Troubleshooting Common Issues](#troubleshooting-common-issues)
9. [Best Practices](#best-practices)

---

## What is CI/CD?

### CI = Continuous Integration
**Continuous Integration** means:
- Every time you push code to GitLab, automatic tests and checks run
- Problems are caught immediately, not when users discover them
- Like having a quality control inspector check every change in real-time

### CD = Continuous Deployment
**Continuous Deployment** means:
- After code passes checks, it's automatically deployed to the target environment
- Instead of manual clicking in the cloud console, deployment happens automatically
- Your infrastructure updates happen without manual intervention

### In Our Project
- **CI Part**: Terraform validates and plans the infrastructure changes
- **CD Part**: Terraform automatically applies approved changes to GCP

---

## How Our Pipeline Works

Here's the complete journey of what happens when you push code:

```
Developer pushes code to main branch
         ↓
GitLab detects the change
         ↓
GitLab CI reads .gitlab-ci.yml
         ↓
Creates a temporary container (runner) with Google Cloud SDK
         ↓
Stage 1: SETUP
  └─ Creates GCS bucket for Terraform state storage
         ↓
Stage 2: TERRAFORM PLAN
  └─ Initializes Terraform
  └─ Validates configuration
  └─ Shows what WILL be created (dry run)
  └─ Saves the plan
         ↓
Stage 3: TERRAFORM APPLY
  └─ Reads the saved plan
  └─ Applies all changes to GCP
  └─ Creates/updates all resources
         ↓
Complete! ✅ Your infrastructure is now updated on GCP
```

---

## The `.gitlab-ci.yml` File Explained

This is the configuration file that tells GitLab how to run your pipeline. Let's break it down section by section:

### Section 1: Base Image

```yaml
image: google/cloud-sdk:alpine
```

**What it means:**
- GitLab needs a container (like a tiny Linux computer) to run your jobs
- We use the official Google Cloud SDK image
- `alpine` means it's very small and lightweight (saves time and money)

**Why this one:**
- Already has Google Cloud tools installed
- Saves time: no need to install gcloud from scratch
- Lightweight: faster pipeline execution


### Section 2: Pipeline Stages

```yaml
stages:
  - setup
  - terraform_plan
  - terraform_apply
  - terraform_destroy
```

**What it means:**
- Pipeline has 4 stages that run sequentially
- Each stage depends on the previous one succeeding

**Stage Order:**
1. **setup**: Prepare the environment
2. **terraform_plan**: Show what changes will happen
3. **terraform_apply**: Actually make the changes
4. **terraform_destroy**: Clean up (optional, runs only if explicitly triggered)

---

### Section 3: Global Variables

```yaml
variables:
  TF_IN_AUTOMATION: "true"
  TF_INPUT: "false"
  TF_REGION: ${REGION}
  GOOGLE_PROJECT: ${PROJECT_ID}
  GOOGLE_PROJECT_NUMBER: ${PROJECT_NUMBER}
  GOOGLE_SERVICE_ACCOUNT: masterclass-sa-gitlab@${PROJECT_ID}.iam.gserviceaccount.com
  WORKLOAD_IDENTITY_PROVIDER: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab
```

**What it means:**
- These are configuration values used throughout the pipeline
- `${VARIABLE}` syntax means these are replaced with actual values

**What each variable does:**

| Variable | Purpose |
|----------|---------|
| `TF_IN_AUTOMATION` | Tells Terraform "you're running in automated mode" (no user input needed) |
| `TF_INPUT` | Set to "false" - don't wait for user input (timeout would fail the pipeline) |
| `TF_REGION` | The Google Cloud region (will be replaced by actual value) |
| `GOOGLE_PROJECT` | Your GCP project ID |
| `GOOGLE_PROJECT_NUMBER` | Your GCP project number (used for OIDC) |
| `GOOGLE_SERVICE_ACCOUNT` | The bot account that GitLab uses |
| `WORKLOAD_IDENTITY_PROVIDER` | The identity pool for secure authentication |

**Where do these values come from?**
- They're stored in GitLab project settings → CI/CD Variables
- You set them up once, GitLab uses them for every pipeline run

---

### Section 4: ID Tokens (Security)

```yaml
.id_tokens:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/${WORKLOAD_IDENTITY_PROVIDER}
```

**What it means:**
- GitLab creates a special security token (like a temporary ID card)
- This token proves "I am a GitLab job, please trust me"
- GCP verifies this token and grants access

**Why this is secure:**
- No passwords or API keys stored in GitLab
- Token expires after each job
- Only works for this specific pipeline and provider
- Much safer than storing credentials as secrets

---

### Section 5: Common Setup (Before Script Template)

```yaml
.before_script_template: &gcp_auth
  - apk add --no-cache bash curl unzip python3 py3-pip git
  - python3 -m venv venv
  - source venv/bin/activate
  - pip install --upgrade pip
  - pip install google-cloud-storage
  # ... more installation commands
```

**What it means:**
- Commands that run BEFORE each job
- Sets up the environment (installs tools needed)
- The `.` at the start means it's a hidden template (not a real job)
- `&gcp_auth` is a label so other jobs can reuse these commands

**What gets installed:**
1. **bash, curl, git**: Basic Linux tools
2. **Python tools**: For running Python scripts
3. **Terraform**: The main tool for infrastructure management
4. **Google Cloud auth tools**: For authenticating with GCP

---

## Pipeline Stages in Detail

### Stage 1: SETUP

```yaml
setup:
  stage: setup
  extends: .id_tokens
  before_script:
    - *gcp_auth
  script:
    - chmod +x $CI_PROJECT_DIR/terraform_project/scripts/backend_bucket/create_backend_bucket.sh
    - $CI_PROJECT_DIR/terraform_project/scripts/backend_bucket/create_backend_bucket.sh ${TF_STATE_BUCKET}
```

**What it does:**
1. Authenticates with GCP using the OIDC token
2. Runs a setup script to create the backend bucket

**What is a "backend bucket"?**
- A special GCS bucket (cloud storage) that stores Terraform state
- Terraform state = a file tracking what infrastructure exists
- Without it, Terraform doesn't know what you've already created

**Why it's a separate stage:**
- Must run first so other stages can use the bucket
- If setup fails, other stages won't run (prevents errors)

---

### Stage 2: TERRAFORM PLAN

```yaml
terraform_plan:
  stage: terraform_plan
  extends: .id_tokens
  dependencies:
    - setup
  before_script:
    - *gcp_auth
  script:
    - cd "$CI_PROJECT_DIR/$TF_ROOT"
    - terraform init -backend-config="bucket=$TF_STATE_BUCKET"
    - terraform fmt -recursive
    - terraform validate
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - $TF_ROOT/tfplan
```

**What it does, step by step:**

1. **Navigate to Terraform files**
   ```bash
   cd "$CI_PROJECT_DIR/$TF_ROOT"
   ```
   - Goes to the directory with your Terraform code

2. **Initialize Terraform**
   ```bash
   terraform init -backend-config="bucket=$TF_STATE_BUCKET"
   ```
   - Prepares Terraform to work
   - Configures where to store state (the backend bucket)
   - Downloads modules from GitHub

3. **Format code**
   ```bash
   terraform fmt -recursive
   ```
   - Makes code look nice and consistent
   - Like running a code formatter on your infrastructure code

4. **Validate configuration**
   ```bash
   terraform validate
   ```
   - Checks if the code has syntax errors
   - Doesn't actually create anything yet

5. **Create a plan**
   ```bash
   terraform plan -out=tfplan
   ```
   - **This is the important step!**
   - Shows EXACTLY what will be created/changed/deleted
   - Saves the plan to a file (`tfplan`)
   - **Does NOT apply changes yet**

**What are artifacts?**
```yaml
artifacts:
  paths:
    - $TF_ROOT/tfplan
```
- Saves the plan file so `terraform_apply` can use it
- Like passing data from one stage to the next

**This stage is like a "preview":**
- You can see what will happen before it happens
- Catch mistakes before they affect your live infrastructure
- Prevents surprises and accidents

---

### Stage 3: TERRAFORM APPLY

```yaml
terraform_apply:
  stage: terraform_apply
  extends: .id_tokens
  dependencies:
    - setup
    - terraform_plan
  before_script:
    - *gcp_auth
  script:
    - cd "$CI_PROJECT_DIR/$TF_ROOT"
    - terraform init -backend-config="bucket=$TF_STATE_BUCKET"
    - terraform apply -auto-approve tfplan
  only:
    - main
```

**What it does:**

1. **Initialize Terraform again**
   - Prepares the environment (same as plan stage)

2. **Apply the saved plan**
   ```bash
   terraform apply -auto-approve tfplan
   ```
   - Takes the plan created in stage 2
   - Actually creates/updates resources on GCP
   - `-auto-approve` means "don't ask for confirmation" (already planned in stage 2)
   - Uses the saved plan (not a new one) to ensure consistency

**When does this run?**
```yaml
only:
  - main
```
- Only runs when you push to the `main` branch
- On other branches, it stops after `terraform_plan`
- This prevents accidental deployments from feature branches

**Why two stages?**
- **Plan stage**: Shows what will happen (verification point)
- **Apply stage**: Actually does it (after plan is verified)
- This separation prevents mistakes

---

## Authentication: OIDC & Workload Identity

This is the secure way GitLab authenticates with GCP. Let's understand it step by step:

### The Problem (Why we need authentication)

```
GitLab: "I want to create resources in GCP"
GCP: "How do I know you're allowed to do that?"
GitLab: "Prove it!"
```

**Traditional way (NOT SECURE):**
- Store API keys in GitLab → easy to leak
- Passwords stored as secrets → can be compromised

**Our way (SECURE):**
- Use temporary tokens that expire quickly
- No passwords stored anywhere
- Uses OIDC (OpenID Connect) standard

### How OIDC Works (Simplified)

```
Step 1: GitLab issues a token
        - Token says: "This is job #12345 from GitLab"
        - Token expires in 1 hour
        ↓
Step 2: GitLab sends token to GCP
        - "I have this token, can you trust me?"
        ↓
Step 3: GCP verifies token
        - Checks if token signature is valid
        - Checks if token is from known GitLab instance
        - Checks if token hasn't expired
        ↓
Step 4: GCP issues temporary credentials
        - "OK, I trust you. Here are temporary GCP credentials"
        - These credentials expire in 1 hour
        ↓
Step 5: GitLab uses credentials to deploy
        - Creates/updates resources
        ↓
Step 6: Credentials expire automatically
        - No ongoing access without new token
```

### Workload Identity Federation

This is what makes OIDC work on GCP:

```yaml
WORKLOAD_IDENTITY_PROVIDER: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab
```

**This setup on GCP creates:**
1. **Identity Pool**: A container for trusted identity providers
2. **Identity Provider**: Trusts GitLab's OIDC tokens
3. **Service Account**: The account that gets the permissions

**The flow:**
```
GitLab OIDC Token
    ↓
Google Cloud Workload Identity Pool
    ↓
Validates & trusts GitLab as source
    ↓
Issues temporary credentials as "masterclass-sa-gitlab"
    ↓
Pipeline uses those credentials
```

---

## Environment Variables

Variables used in the pipeline come from different places:

### 1. Global Variables (in .gitlab-ci.yml)

```yaml
variables:
  TF_IN_AUTOMATION: "true"
  TF_REGION: ${REGION}
```

- Defined in the YAML file itself
- `${REGION}` = replaced by CI/CD variable value

### 2. CI/CD Variables (in GitLab Project Settings)

You need to set these in GitLab: **Settings → CI/CD → Variables**

```
PROJECT_ID = your-gcp-project-id
PROJECT_NUMBER = 123456789
REGION = us-central1
TF_STATE_BUCKET = my-terraform-state-bucket
TF_ROOT = terraform_project/envs/dev
```

| Variable | What to put | Example |
|----------|------------|---------|
| `PROJECT_ID` | Your GCP Project ID | `masterclassparis` |
| `PROJECT_NUMBER` | Your GCP Project Number | `123456789012` |
| `REGION` | Google Cloud region | `us-central1` |
| `TF_STATE_BUCKET` | Bucket name for state | `masterclass-state-prod` |
| `TF_ROOT` | Path to Terraform files | `terraform_project/envs/dev` |

### 3. Built-in Variables (from GitLab)

GitLab automatically provides these (no setup needed):

```yaml
CI_PROJECT_DIR      # Project directory
CI_COMMIT_BRANCH    # Current branch name
CI_JOB_ID          # Job ID
CI_PIPELINE_ID     # Pipeline ID
```

**Example: Using built-in variables**
```yaml
script:
  - echo "Running job $CI_JOB_ID in project $CI_PROJECT_DIR"
```

---

## Running the Pipeline

### What Triggers a Pipeline?

1. **Push to GitLab**
   ```bash
   git commit -m "Update infrastructure"
   git push origin main
   ```
   - Automatic: pipeline starts immediately

2. **Manually from GitLab UI**
   - Go to **CI/CD → Pipelines → Run Pipeline**
   - Select branch
   - Click "Run pipeline"

3. **Merge Request**
   - Create MR from feature branch
   - Plan stage runs (apply stage skipped)
   - Merge then applies

### Viewing Pipeline Status

**In GitLab:**
1. Go to **CI/CD → Pipelines**
2. Click on a pipeline
3. See all stages and jobs
4. Click on a job to see output

**Pipeline can have these statuses:**
- 🟡 **Pending**: Waiting to start
- 🔵 **Running**: Currently executing
- ✅ **Passed**: Completed successfully
- ❌ **Failed**: Had an error
- ⏭️ **Skipped**: Conditions weren't met

---

## Troubleshooting Common Issues

### Problem 1: Authentication Failed

**Error Message:**
```
ERROR: (gcloud.iam.workload-identity-pools.create-cred-config) 
Could not find the service account
```

**Causes & Solutions:**
1. Service account doesn't exist
   - Solution: Run `masterclass-sa-gitlab.sh`

2. Wrong PROJECT_ID variable
   - Solution: Check GitLab CI/CD variables

3. Workload Identity not configured
   - Solution: Run the setup script to configure it

---

### Problem 2: Terraform State Locked

**Error Message:**
```
Error acquiring the state lock
```

**What it means:**
- Another pipeline is modifying the state
- Or a previous pipeline crashed while holding the lock

**Solutions:**
1. Wait for other pipeline to finish
2. If stuck, force-unlock:
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

---

### Problem 3: Backend Bucket Not Found

**Error Message:**
```
bucket "my-bucket" does not exist
```

**Causes & Solutions:**
1. Bucket doesn't exist
   - Solution: Set `TF_STATE_BUCKET` variable correctly

2. Wrong bucket name in variables
   - Solution: Check the variable value in GitLab

3. Permissions missing
   - Solution: Run service account setup script again

---

### Problem 4: Resources Already Exist

**Error Message:**
```
Error 409: The repository my-repo already exists
```

**Causes:**
- You ran apply twice
- Infrastructure was created manually before Terraform

**Solutions:**
1. Import existing resources:
   ```bash
   terraform import google_artifact_registry_repository.repo gs://my-repo
   ```

2. Delete and recreate:
   ```bash
   terraform destroy
   terraform apply
   ```

---

## Best Practices

### 1. Always Review Plan Before Merge

**Before merging a PR:**
- Check the pipeline plan output
- Review what resources will be created/changed
- Make sure changes are expected

**How:**
- Go to Merge Request
- Scroll down to see pipeline logs
- Review plan output carefully

---

### 2. Use Protected Branches

**Protect main branch:**
- **Settings → Repository → Protected Branches**
- Set rules:
  - Require code review before merge
  - Require all pipelines to pass
  - Require specific approval

**Benefits:**
- Prevents accidental merges
- Infrastructure changes are reviewed
- Automatic rollback via pipeline restart

---

### 3. Start with Small Changes

**When learning:**
1. Change just one variable
2. Run `terraform plan`
3. Review plan output
4. Run `terraform apply`
5. Verify resources on GCP
6. Destroy and try again

---

### 4. Separate Environments

**Create separate branches/directories:**
```
terraform_project/
  envs/
    dev/        # Development (test here first)
    staging/    # Staging (pre-production)
    prod/       # Production (most careful)
```

**For each:**
- Separate CI/CD variables
- Different Terraform workspaces
- Different approval requirements

---

### 5. Monitor Pipeline Logs

**Always check logs for:**
- Warnings (yellow text)
- Resource creation status
- Any unusual behavior

**How:**
- Click job in pipeline
- Scroll through output
- Look for errors or warnings

---

### 6. Test Locally Before Pushing

**Use Terraform locally:**
```bash
cd terraform_project/envs/dev

# Validate
terraform validate

# Format check
terraform fmt -recursive

# See what will happen
terraform plan
```

**Benefits:**
- Catch errors before pipeline
- Understand changes before applying
- Save CI/CD minutes

---

### 7. Keep Secrets Secure

**DO:**
- Store sensitive values in CI/CD Variables (marked as secret)
- Use service accounts instead of personal accounts
- Rotate credentials regularly

**DON'T:**
- Commit credentials to Git
- Store passwords in code
- Share CI/CD variable values

---

### 8. Have a Rollback Plan

**If something goes wrong:**
1. Pipeline failed? Fix the Terraform error
2. Wrong resources created? Use `terraform destroy`
3. Need to revert? Use Git to revert commit, pipeline will undo changes

**Always able to:**
```bash
git revert <commit>
git push
# Pipeline automatically reverts the infrastructure
```

---

## Common Terraform Commands in Pipeline

| Command | What it does |
|---------|------------|
| `terraform init` | Initialize (downloads modules, sets up backend) |
| `terraform fmt` | Format code (beautify) |
| `terraform validate` | Check for syntax errors |
| `terraform plan` | Show what will change |
| `terraform apply` | Actually make changes |
| `terraform destroy` | Delete all resources |
| `terraform state list` | See all managed resources |
| `terraform import` | Add existing resource to state |
| `terraform force-unlock` | Unlock stuck state |

---

## Advanced Topics

### Custom Pipeline Variables

Pass variables during manual pipeline trigger:
1. Go to **CI/CD → Pipelines**
2. Click **Run Pipeline**
3. Expand **Variables**
4. Add custom variable and value
5. Click **Run Pipeline**

### Conditional Job Execution

Run jobs only on specific conditions:

```yaml
terraform_apply:
  only:
    - main           # Only on main branch
  when: manual       # Require manual trigger
```

### Pipeline Artifacts

Share files between stages:

```yaml
artifacts:
  paths:
    - tfplan        # Save these files
  expire_in: 1 week # Keep for 1 week
```

---

## Quick Reference

### To Trigger a Pipeline:
```bash
git commit -m "Update infrastructure"
git push origin main
```

### To Check Pipeline Status:
1. Go to **CI/CD → Pipelines**
2. Find your pipeline
3. Watch it progress through stages

### To View Logs:
1. Click on pipeline
2. Click on job (setup, terraform_plan, terraform_apply)
3. Scroll to see output

### To Fix Common Errors:
1. Read the error message in job logs
2. Check CI/CD variables in GitLab settings
3. Verify Terraform code syntax locally
4. Check GCP resources exist
5. Verify service account has permissions

---

## Summary

**GitLab CI/CD in MasterClassParis does:**

1. ✅ Triggers when you push code
2. ✅ Authenticates securely with GCP using OIDC
3. ✅ Plans infrastructure changes (terraform plan)
4. ✅ Shows you exactly what will change
5. ✅ Applies approved changes (terraform apply)
6. ✅ Creates resources automatically on GCP
7. ✅ Stores state securely in GCS bucket
8. ✅ Provides complete audit trail in Git

**Benefits:**
- 🔒 Secure authentication (no stored passwords)
- 🔄 Repeatable and consistent deployments
- 📝 Full history of every change
- ⚠️ Plans shown before applying
- ⏱️ Automatic and fast
- 👀 Fully transparent with logs visible

---

## Next Steps

1. **Set up your CI/CD variables** in GitLab (PROJECT_ID, REGION, etc.)
2. **Configure Workload Identity Federation** on GCP
3. **Make a test commit** to trigger the pipeline
4. **Watch the pipeline** run in GitLab
5. **Review the changes** on GCP
6. **Experiment** with modifying the Terraform files

---

**Questions? Check the GitLab documentation or modify your code and watch the pipeline run!** 🚀

