#!/usr/bin/env bash

set -ex
cd ansible/

time ansible-playbook --vault-password-file .vault_pass -T 180 $@
