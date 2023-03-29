NAMESPACE=devops-practice
PROJECT_ID=devops-demo-4569
ZONE=asia-east1-c
ENV=staging

#####################################################################
# Run the local development environment.
#####################################################################
run-local:
	docker-compose up 


#####################################################################
# Create a new project and set it as the default project.
#####################################################################
gcp_create_project:
	gcloud auth login --no-launch-browser
	gcloud projects create $(PROJECT_ID) \
		--name="DevOpsDemo"
	gcloud config set project $(PROJECT_ID)
	gcloud projects describe $(PROJECT_ID)
	gcloud auth application-default login
	gcloud services enable cloudresourcemanager.googleapis.com


#####################################################################
# Create a backend bucket and IAM for Terraform state file.
#####################################################################
# Create a GCS for storing Terraform state file.
create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform

# Create a service account for Terraform to access the backend bucket.
create-tf-backend-bucket-iam:
	gcloud iam service-accounts create terraform-sa \
	 	--display-name "Terraform Service Account"
	gsutil iam ch \
		serviceAccount:terraform-sa@$(PROJECT_ID).iam.gserviceaccount.com:roles/storage.objectAdmin \
		gs://$(PROJECT_ID)-terraform
# Create a key for the service account.
create-tf-backend-bucket-iam-key:
	gcloud iam service-accounts keys create \
		terraform/terraform-sa-key.json \
		--iam-account terraform-sa@$(PROJECT_ID).iam.gserviceaccount.com

check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

tf-preinit:
	cd terraform && \
	export GOOGLE_APPLICATION_CREDENTIALS=terraform-sa-key.json && \
	terraform init

tf-create-workspace: check-env
	cd terraform && \
		terraform workspace new $(ENV)

tf-init: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

# This cannot be indented or else make will include spaces in front of secret
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

TF_CMD?=plan
tf-cmd: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform ${TF_CMD} \
		-var-file="./envs/common.tfvars" \
		-var-file="./envs/$(ENV)/config.tfvars" \
		-var="mongodbatlas_private_key=$(call get-secret,mongodbatlas_private_key)" \
		-var="mongodbatlas_user_password=$(call get-secret,mongodbatlas_user_password_$(ENV))" \
		-var="cloudflare_api_token=$(call get-secret,cloudflare_api_token)"


SSH_STRING=devops-practice-vm-$(ENV)
ssh:
	gcloud compute ssh $(SSH_STRING) \
		--project $(PROJECT_ID) \
		--zone $(ZONE)

ssh-cmd:
	gcloud compute ssh $(SSH_STRING) \
		--project $(PROJECT_ID) \
		--zone $(ZONE) \
		--command="${CMD}"

GITHUB_SHA?=latest
LOCAL_TAG=$(NAMESPACE):$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)
build:
	docker build -t $(LOCAL_TAG) .
push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

OAUTH_CLIENT_ID=342139977677-ml64tsiq924qlhjpep7rm2pamp8bv8f0.apps.googleusercontent.com
deploy: check-env
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'

	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'

	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'

	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URL=mongodb+srv://devops-practice-user-$(ENV):$(call get-secret,mongodbatlas_user_password_$(ENV))@devops-practice-$(ENV).vvsap.mongodb.net/$(NAMESPACE)?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(OAUTH_CLIENT_ID) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,google_oauth_client_secret) \
			$(REMOTE_TAG) \
			'