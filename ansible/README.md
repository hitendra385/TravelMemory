# TravelMemory Ansible Deployment

Ansible configures the Terraform-created Amazon Linux 2023 hosts. It installs MongoDB on the private database host, installs Node.js and Nginx on the public web host, builds the React frontend, runs the Express API under systemd, and proxies `/trip` and `/hello` through Nginx. The web security group is the perimeter firewall; MongoDB and database SSH are restricted to the web security group. The playbook also enables the host firewall and disables SSH root/password login.

## Prerequisites

- Terraform has successfully applied `../terraform` and its local state is available.
- AWS CLI credentials are available to the shell so Terraform outputs can be read. The deployment helper inherits `AWS_PROFILE`.
- Ansible is installed on the control machine. On macOS with Homebrew, run `brew install ansible`.
- The deployment helper installs the pinned playbook collection requirements with `ansible-galaxy` before connecting.
- The private key file for the EC2 key pair is on the control machine. Do not commit it or copy it to the web server.

## Prepare SSH

Set the key path in your shell and restrict its permissions:

```sh
export ANSIBLE_PRIVATE_KEY_FILE="$HOME/Downloads/flask-practice_KeyPair.pem"
chmod 400 "$ANSIBLE_PRIVATE_KEY_FILE"
```

Replace the example path with the location where you saved the key. The key-pair name must be the same as `ec2_key_pair_name` in Terraform.

With SSH host-key checking enabled, connect once to each host so OpenSSH can ask you to verify and trust the host keys:

```sh
ssh -i "$ANSIBLE_PRIVATE_KEY_FILE" ec2-user@"$(terraform -chdir=../terraform output -raw web_public_ip)"
```

Exit that session, then connect to the private host through the web host:

```sh
ssh -i "$ANSIBLE_PRIVATE_KEY_FILE" \
  -J ec2-user@"$(terraform -chdir=../terraform output -raw web_public_ip)" \
  ec2-user@"$(terraform -chdir=../terraform output -raw database_private_ip)"
```

## Deploy

From the repository root, run:

```sh
bash ansible/deploy.sh
```

The helper reads the current IPs from Terraform outputs, creates a temporary SSH inventory, loads the private key into a temporary SSH agent if needed, checks Ansible connectivity, and runs the playbook. It does not store inventory IPs or secrets in the repository. The playbook prompts for the MongoDB administrator and application-user passwords, confirms both, and does not print them.

Use separate, URL-safe passwords and keep both in a password manager. Enter the same values on future playbook runs; the playbook synchronizes the application-user password between MongoDB and the API environment.

When deployment completes, open `http://$(terraform -chdir=terraform output -raw web_public_ip)`. Nginx serves the React build and proxies API calls to Express on localhost. Port 3001 is not opened publicly. This assignment setup uses HTTP; HTTPS needs a domain and TLS certificate.

Check service status with SSH:

```sh
sudo systemctl status nginx travelmemory-api
```

On the database host, check MongoDB with `sudo systemctl status mongod`.

## Security and cleanup

The database is private and requires MongoDB authentication. The app user receives only `readWrite` on the TravelMemory database; the separate MongoDB administrator credentials are not written into the repository. The API environment file is root-owned and readable only by the service group. The host firewall and AWS security groups limit inbound ports, while SSH requires the EC2 key pair.

AWS infrastructure remains billable until Terraform destroys it. From the repository root, remove it when finished with:

```sh
terraform -chdir=terraform destroy
```