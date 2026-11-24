This is supposed to be a comprehensive list of accounts needed to develop and operate this project.

Alphabetical Order:

* Amazon Web Services - Staging and production infrastructure, provisioned by the sibling `core-iac` repo: EKS cluster, RDS PostgreSQL, and Route 53 (domain registration and DNS for automation-calculations.io and automation-calculations.net)
* CircleCI - Build Pipeline
* [Docker Hub](https://hub.docker.com/r/automationcalculationsci/automation-calculator/) - Docker Image Repository
* GitHub - Code Repository, and the OAuth app behind "Sign in with GitHub"
* Google Cloud - The OAuth client behind "Sign in with Google"
* HCP Terraform (Terraform Cloud) - Terraform state and runs for `core-iac`
* Papertrail - Logs
