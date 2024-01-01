deploy HOST:
    ansible-playbook -i ./inventories playbooks/site.yml --limit {{ HOST }}

deploy-password HOST:
    ansible-playbook -i./inventories playbooks/site.yml --limit {{ HOST }} --ask-pass --ask-become-pass

lint:
    yamllint .
    ansible-lint

deps:
    pip install -r ansible/dev-requirements.txt
    ansible-galaxy install -r ansible/galaxy-requirements.yml --force
