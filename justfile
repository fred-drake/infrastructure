deploy HOST:
    ansible-playbook ansible/playbooks/site.yml --limit {{ HOST }}

deploy-password HOST:
    ansible-playbook ansible/playbooks/site.yml --limit {{ HOST }} --ask-pass --ask-become-pass

playbook PLAYBOOK:
    ansible-playbook ansible/playbooks/{{ PLAYBOOK }}.yml

playbook-host PLAYBOOK HOST:
    ansible-playbook ansible/playbooks/{{ PLAYBOOK }}.yml --limit {{ HOST }}

proxy APP:
    ansible-playbook ansible/playbooks/{{ APP }}.yml -e "justmode=proxy"

app APP:
    ansible-playbook ansible/playbooks/{{ APP }}.yml -e "justmode=app"

update APP:
    ansible-playbook ansible/playbooks/{{ APP }}.yml -e "justmode=update"

config APP:
    ansible-playbook ansible/playbooks/{{ APP }}.yml -e "justmode=config"

dns:
    ansible-playbook ansible/playbooks/dns_update.yml

dhcp:
    ansible-playbook ansible/playbooks/dhcp_update.yml

lint:
    yamllint .
    ansible-lint

deps:
    pip install -r ansible/dev-requirements.txt
    ansible-galaxy install -r ansible/galaxy-requirements.yml --force

secrets:
    ansible-playbook ansible/playbooks/generate_sealed_secrets.yml

kube-encrypt:
    cp -f kubeconfig kubeconfig.sops.yaml
    sops --encrypt --in-place kubeconfig.sops.yaml

kube-decrypt:
    sops --decrypt kubeconfig.sops.yaml > kubeconfig

kube-delete-snapshots-of-pvc PVC:
    kubectl get snapshots.longhorn.io -n longhorn -l longhornvolume=pvc-a70959c0-a038-4e11-9514-bfb9837093bd -o json | jq -r '.items |= sort_by(.metadata.creationTimestamp) | .items[].metadata.name' | xargs -I {} kubectl delete snapshots.longhorn.io -n longhorn {}

nixinit HOST:
    nixinit {{ HOST }}

nix HOST:
    nixupdate {{ HOST }}

tf-plan:
    tofu -chdir=terraform plan

tf-apply:
    tofu -chdir=terraform apply
