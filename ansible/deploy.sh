#!/usr/bin/env bash
set -euo pipefail

ansible_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$ansible_dir/.." && pwd)"
key_file="${ANSIBLE_PRIVATE_KEY_FILE:-}"

if [[ -z "$key_file" || ! -r "$key_file" ]]; then
  printf '%s\n' 'Set ANSIBLE_PRIVATE_KEY_FILE to the readable path of your EC2 .pem key.' >&2
  exit 1
fi

command -v terraform >/dev/null || { printf '%s\n' 'Terraform is required.' >&2; exit 1; }
command -v ansible-playbook >/dev/null || { printf '%s\n' 'Install Ansible first; see ansible/README.md.' >&2; exit 1; }
command -v ansible-galaxy >/dev/null || { printf '%s\n' 'ansible-galaxy is required; reinstall Ansible.' >&2; exit 1; }
command -v ssh-add >/dev/null || { printf '%s\n' 'OpenSSH ssh-add is required.' >&2; exit 1; }
ansible-galaxy collection install -r "$ansible_dir/requirements.yml"

web_ip="$(terraform -chdir="$repo_root/terraform" output -raw web_public_ip)"
database_ip="$(terraform -chdir="$repo_root/terraform" output -raw database_private_ip)"
inventory_file="$(mktemp)"
agent_pid=""

cleanup() {
  if [[ -n "$agent_pid" ]]; then
    ssh-agent -k >/dev/null 2>&1 || true
  fi
  rm -f "$inventory_file"
}
trap cleanup EXIT

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  eval "$(ssh-agent -s)" >/dev/null
  agent_pid="$SSH_AGENT_PID"
fi
ssh-add -q "$key_file"

cat > "$inventory_file" <<EOF
[web]
web_server ansible_host=$web_ip ansible_user=ec2-user

[database]
database_server ansible_host=$database_ip ansible_user=ec2-user ansible_ssh_common_args='-o ProxyJump=ec2-user@$web_ip'
EOF

export ANSIBLE_CONFIG="$ansible_dir/ansible.cfg"
ansible all -i "$inventory_file" --private-key "$key_file" -m ping
ansible-playbook -i "$inventory_file" --private-key "$key_file" "$ansible_dir/site.yml"