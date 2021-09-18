#!/usr/bin/env bash

USAGE="usage: encdec.sh <encrypt|decrypt>"
if [ -z $1 ]; then
    echo $USAGE
    exit 1
fi
if [ "$1" != "encrypt" ] && [ "$1" != "decrypt" ]; then
    echo $USAGE
    exit 1
fi 


cd ansible/
echo "--- All files with the filename vault.yml"
for i in $(find . -name vault.yml); do
    echo -n "   --- $i: "
            ansible-vault $1 $i --vault-password-file .vault_pass
done

while read f; do
    if [[ -d "$f" ]]; then
        echo "--- All files in directory $f"
        for i in $(find $f -type f); do
            echo -n "   --- $i: " 
            ansible-vault $1 $i --vault-password-file .vault_pass
        done
    elif [[ -f "$f" ]]; then
        echo -n "--- $f: "
        ansible-vault $1 --vault-password-file .vault_pass $f
    else
        echo "$f IS NOT VALID"
    fi
done < encrypted_files.txt
