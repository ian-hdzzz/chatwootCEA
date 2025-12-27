# Google Cloud Deployment Guide for Chatwoot

This guide contains the complete list of commands to deploy Chatwoot to Google Cloud Platform (GCP).

## Prerequisites

Ensure you have the Google Cloud CLI installed and authenticated.

```bash
# Login to Google Cloud
gcloud auth login
```

## 1. Environment Setup

Set these variables at the start of your session to use throughout the commands.

```bash
# REPLACE THESE WITH YOUR VALUES
export PROJECT_ID="clever-obelisk-277705"       # The GCP Project ID
export REGION="us-central1"               # Region (e.g., us-central1)
export SERVICE_NAME="chatwoot-cea"        # Cloud Run Service Name
export DB_INSTANCE_NAME="chatwoot-db"     # Cloud SQL Instance Name
export REDIS_NAME="chatwoot-redis"        # Redis Instance Name
export REPO_NAME="chatwoot-repo"          # Artifact Registry Repository Name

# Set the active project
gcloud config set project $PROJECT_ID
```

## 2. Enable Required APIs

Enable the necessary Google Cloud services.

```bash
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  compute.googleapis.com \
  servicenetworking.googleapis.com \
  vpcaccess.googleapis.com \
  redis.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com
```

## 3. Network Configuration

**Skipped** (Using "No VPC" strategy with external Redis).

## 4. Create Resources

### 4.1 Create External Redis

Since we are avoiding VPC, you must use an external Redis provider accessible over the public internet (with a password).

**Recommended Providers (Free Tiers available):**
- [Upstash Redis](https://upstash.com/)
- [Redis Cloud](https://redis.com/try-free/)
- [Aiven for Redis](https://aiven.io/redis)

1. Create a database with one of these providers.
2. Get the **Connection String** (starts with `rediss://...` or `redis://...`).
3. You will put this in your `env.yaml` later.

### 4.2 Create PostgreSQL (Cloud SQL)

Cloud SQL can also be accessed via public IP (secured by Auth Proxy, which Cloud Run handles automatically, or by whitelisting IPs).


```bash
# Create the instance
gcloud sql instances create $DB_INSTANCE_NAME \
  --database-version=POSTGRES_14 \
  --region=$REGION \
  --cpu=2 \
  --memory=4GiB

# Create the database
gcloud sql databases create chatwoot_production --instance=$DB_INSTANCE_NAME

# Create the user
gcloud sql users create chatwoot_user \
  --instance=$DB_INSTANCE_NAME \
  --password="YOUR_SECURE_PASSWORD"
```

### 4.3 Create Artifact Registry

```bash
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION
```

## 5. Build and Push Image

```bash
# Submit build to Cloud Build
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME:latest .
```

## 6. Initial Deployment (Migration)

You need to run migrations before the app can start effectively.

> **Note:** Cloud Run is stateless. Running `rails db:chatwoot_prepare` as a separate job is the cleanest way.

1. Create a `env.yaml` file with your secrets:

```yaml
# env.yaml
RAILS_ENV: "production"
NODE_ENV: "production"
RAILS_LOG_TO_STDOUT: "true"
FRONTEND_URL: "https://YOUR_FINAL_CLOUD_RUN_URL"
SECRET_KEY_BASE: "GENERATE_A_LONG_SECRET_KEY"
POSTGRES_HOST: "/cloudsql/YOUR_PROJECT_ID:$REGION:$DB_INSTANCE_NAME"
POSTGRES_USERNAME: "chatwoot_user"
POSTGRES_PASSWORD: "YOUR_SECURE_PASSWORD"
POSTGRES_DATABASE: "chatwoot_production"
REDIS_URL: "rediss://default:password@your-redis-instance.upstash.io:6379"
```

2. Run the migration job:

```bash
gcloud run jobs create migrate-chatwoot \
  --image=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME:latest \
  --region=$REGION \
  --set-cloudsql-instances=$PROJECT_ID:$REGION:$DB_INSTANCE_NAME \
  --env-vars-file=env.yaml \
  --command="bundle,exec,rails,db:chatwoot_prepare"

gcloud run jobs execute migrate-chatwoot --region=$REGION
```


## 7. Deploy Service

```bash
gcloud run deploy $SERVICE_NAME \
  --image=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME:latest \
  --region=$REGION \
  --allow-unauthenticated \
  --set-cloudsql-instances=$PROJECT_ID:$REGION:$DB_INSTANCE_NAME \
  --env-vars-file=env.yaml \
  --port=8080 \
  --memory=2Gi \
  --cpu=2
```

## 8. Final Configuration

After deployment, update the `FRONTEND_URL` in your `env.yaml` or directly on the service with the URL Cloud Run assigned to you.
```bash
gcloud run services update $SERVICE_NAME \
  --region=$REGION \
  --env-vars-file=env.yaml
```


## 9. Alternative: Deploy automatically from GitHub

Yes, you can deploy directly from your GitHub repository! This is called **Continuous Deployment**. Every time you push to the `main` branch, Google Cloud will automatically build and deploy your app.

### 9.1 Connect Repository

1. Go to the [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers) in the Google Cloud Console.
2. Click **Create Trigger**.
3. **Name**: `deploy-chatwoot-on-push`
4. **Event**: push to a branch.
5. **Source**: Select your GitHub repository. (You may need to "Connect new repository" first).
6. **Branch**: `^main$` (or your default branch).

### 9.2 Configure Build Configuration

1. **Configuration**: Select "Cloud Build configuration file (yaml or json)".
2. **Location**: `cloudbuild.yaml` (default).

### 9.3 Add Substitution Variables

In the trigger settings, add the following **Substitution variables**. These replace the variables used in `cloudbuild.yaml`:

| Variable | Value |
| :--- | :--- |
| `_SERVICE_NAME` | `chatwoot-cea` |
| `_REGION` | `us-central1` |
| `_REPO_NAME` | `chatwoot-repo` |

### 9.4 Permissions

Cloud Build needs permission to deploy to Cloud Run.

1. Go to **IAM & Admin** > **IAM**.
2. Find the "Cloud Build Service Account" (usually `PROJECT_NUMBER@cloudbuild.gserviceaccount.com`).
3. Add the role: **Cloud Run Admin** and **Service Account User**.

Now, whenever you push code to GitHub, Google Cloud will see the change, run the steps in `cloudbuild.yaml`, and update your live application automatically.
