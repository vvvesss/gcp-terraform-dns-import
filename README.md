
# DNS Record Importer for GCP to Terraform

This script helps you import DNS records from Google Cloud Platform (GCP) into Terraform and generate the corresponding Terraform resource definitions. It retrieves DNS record sets from a specified GCP DNS zone, creates an import command to import the existing records into Terraform, and generates Terraform configuration files for managing those records.

## Prerequisites

Before running this script, ensure you have:

1. **Google Cloud SDK (`gcloud`)** installed and authenticated.
2. **Terraform** installed on your machine.
3. A **GCP project** with DNS records in the specified zone.
4. A **GCS bucket** configured for Terraform remote state.

## Setup

1. Ensure you have a `provider` and `terraform` configuration, such as in the example below.

2. Set up your `variables.tf` with the required values for your GCP project and DNS zone.

### Example `provider.tf`

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

terraform {
  backend "gcs" {
    bucket = "55444336bd069be9c-terraform-remote-backend"
    prefix = "terraform/state/your-gcp-project-dns"
  }
}
```

### Example `variables.tf`

```hcl
# Mandatory for Terraform provider

variable "project_id" {
  default = "your-gcp-project"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-c"
}
```

Make sure to replace the `project_id`, `region`, and `zone` variables with your actual GCP project ID, region, and DNS zone.

## Usage

1. **Clone or download the script** to your local machine.
2. Modify the script to set your DNS zone in the `zone` variable:

```ruby
zone = "your-gcp-dns-zone-name"
```

3. Run the script:

```bash
ruby dns_importer.rb
```

### What It Does

- **Imports DNS Records**: The script fetches all DNS records from the specified GCP DNS zone using the `gcloud` CLI.
- **Generates Terraform Configuration**: It creates Terraform resources for each DNS record found in the zone and writes them to `.tf` files.
- **Generates Import Commands**: The script generates the `terraform import` commands and writes them to an `import.sh` file. You can run these commands to import the existing DNS records into your Terraform state.

## Files Generated

1. **`import.sh`**: A shell script that contains `terraform import` commands for all DNS records in the specified zone.
   - Example:
     ```bash
     terraform import google_dns_record_set.example_record "projects/your-gcp-project/managedZones/your-zone-name/rrsets/example.com/A"
     ```

2. **`<record-name>_<type>.tf`**: A Terraform configuration file for each DNS record. These files define the `google_dns_record_set` resource and include all the details of the DNS record.

   - Example for an `A` record:
     ```hcl
     resource "google_dns_record_set" "example_record_a" {
       name         = "example.com."
       type         = "A"
       ttl          = 300
       managed_zone = "your-zone-name"
       rrdatas = [
         "10.193.93.4"
       ]
     }
     ```

   - Example for a `TXT` record:
     ```hcl
     resource "google_dns_record_set" "example_record_txt" {
       name         = "example.com."
       type         = "TXT"
       ttl          = 300
       managed_zone = "your-zone-name"
       rrdatas = [
         "\"v=spf1 include:_spf.google.com ~all\""
       ]
     }
     ```

   - Example for an `SRV` record:
     ```hcl
     resource "google_dns_record_set" "example_record_srv" {
       name         = "_mongodb._tcp.example.com."
       type         = "SRV"
       ttl          = 300
       managed_zone = "your-zone-name"
       rrdatas = [
         "0 0 27017 mongodb.example.com."
       ]
     }
     ```

### Special Cases

- **SRV Records**: SRV records will have their `rrdatas` split and formatted properly as a list of values.
- **TXT Records**: The script automatically escapes double quotes in the TXT records for compatibility with Terraform syntax.

### Important Notes

- The generated Terraform files and import commands will need to be executed in the directory where Terraform can access your backend configuration.
- Make sure to run the generated `import.sh` script first to import your existing records into the Terraform state before applying any changes.

## License

This script is open-source and available under the MIT License.
