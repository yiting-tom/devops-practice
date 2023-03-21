# Providers

| | |
| --- | --- |
| **Status** | Pending Approval |
| **Author** | [Yi-Ting Li](yiting-tom.github.io) |
| **Version** | 1.0.0 |
| **Last Updated** | 2023-03-21 |
| **Created At** | 2023-03-21 |

## Table of Contents

* [Providers](#providers)
   * [Downloading Providers](#downloading-providers)
   * [Declaration of Providers](#declaration-of-providers)
   * [Version Constraints](#version-constraints)
      * [Warning](#️-warning)

---

Terraform relies on the [go-plugin](https://github.com/hashicorp/go-plugin) established by HashiCorp. Each provider plugin runs as an independent process and communicates with Terraform via remote procedure calls (RPC).

Terraform executes three main functions:
1. Reads and analyzes the Terraform script written by the user.
2. Generates multiple graphs (constructed by **data** & **resource**) that represent the infrastructure resources and their dependencies.
3. Calls the provider plugins via RPC to create, read, update, or delete resources.

![](https://i.imgur.com/9hnkHvG.png)

<details><summary>How to provide a `Provider`?</summary>
Providers should adhere to the structure defined by Terraform and implement the CRUD methods for accessing the SDK or HTTP/HTTPS API. This ensures that Terraform can interact with the provider's resources consistently and effectively.
</details>

## Downloading Providers
When you run the `terraform init` command, Terraform downloads the necessary provider plugins and saves them in the `plugins` folder within the `.terraform` directory. To ensure that each Terraform project is independent, Terraform generates a new `plugins` folder for each project.

However, this can lead to multiple copies of the same plugins being stored on your disk, which can be wasteful. To solve this, you can cache the plugins in one of two ways:

1. Environment Variable
   You can set the `TF_PLUGIN_CACHE_DIR` environment variable to specify a directory where Terraform can cache the plugins. This will prevent Terraform from downloading the same plugin multiple times for different projects.

2. CLI Configuration
   Alternatively, you can create a `.terraformrc` configuration file in your `$HOME` directory and add `plugin_cache_dir="<cache-dir>"` to the file. This will also cache the plugins and prevent duplication.

By caching the plugins, you can speed up the initialization of Terraform projects and reduce disk usage.


## Declaration of Providers
To use modules or resources provided by a provider, we need to declare the provider and provide it with the necessary arguments. For instance, to use the [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs), we must declare the provider first.

In the following script, I declare the Google provider with version "4.57.0" and source "hashicorp/google"(The source address is constructed using three parts: `[<hostname>/]<namespace>/<type>`. The default value for `[hostname]` is `registry.terraform.io`). After the declaration, we can use the Google provider in line #12.
Also, we have to provide the `Provider` with other necessary arguments, such as the `project` and `region` in the case of the Google provider.

```hcl
// specify the version of Terraform and providers
terraform {
  required_version = "0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
  }
}

provider "google" {
  project = "project-id"
  region  = "asia-east1"
}
```

## Version Constraints

All version constraints in Terraform use the <major>.<minor>.<patch> format. We can specify the version using these following symbols and `,` to do the AND operation, e.g., `">=1.1.0,<1.2.0"`
    
1. `=` or the version number: strictly specify the version.
2. `!=`: do not allow this version.
3. `>,>=,<,<=`: specify a range of versions.
4. `~>`: specify a range of compatible versions (allows patch updates).
    
We can also access the same provider with different setups by declaring multiple local names for the same provider. In the following script, we declare the Google provider twice, once for the "asia-east1" region and once for the "us-west1" region. We use different local names, `google_tw` and `google_us`, to differentiate between the two.

```terraform
terraform {
  required_version = "0.13"
  required_providers {
    google_tw = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
    google_us = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
  }
}

provider "google_tw" {
  project = "project-id"
  region  = "asia-east1"
}

provider "google_us" {
  project = "project-id"
  region  = "us-west1"
}

data "google_compute_address" "tw_address" {
  provider = google_tw
  name     = "tw_address"
}

data "google_compute_address" "us_address" {
  provider = google_us
  name     = "us_address"
}
```

Alternatively, we can use the alias argument to give the same provider multiple names with different configurations. In the following script, we declare the Google provider once and give it an alias, google_us, with a different configuration for the "us-west1" region.
    
```terraform
terraform {
  required_version = "0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
  }
}

provider "google" {
  project = "project-id"
  region  = "asia-east1"
}

provider "google" {
  alias   = "google_us"
  project = "project-id"
  region  = "us-west1"
}

data "google_compute_address" "tw_address" {
  name = "tw_address"
}

data "google_compute_address" "us_address" {
  provider = google.google_us
  name     = "us_address"
}
```
### ⚠️ Warning    
Every provider declaration **without** the alias attribute is a **default** provider declaration. Data and resources that do not explicitly specify a provider use the default provider that corresponds to the first word of the resource name.

If all explicitly declared providers in the code have aliases, Terraform constructs a default provider with empty configurations at runtime. If the provider has required fields and a resource uses the default provider, Terraform will throw an error complaining that the default provider is missing the required fields.