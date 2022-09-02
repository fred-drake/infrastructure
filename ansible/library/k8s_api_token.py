#!/usr/bin/python3

from ansible.module_utils.basic import AnsibleModule
import subprocess


class AppException(Exception):
    pass


def execute_process(process):
    result = subprocess.run(
        process, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if result.returncode != 0:
        raise AppException(result.stderr)

    return result.stdout


def handle_token():
    secret = execute_process(["kubectl get secrets | grep ^default | cut -f1 -d ' '"])
    secret = secret.strip()
    token = execute_process(
        [
            "kubectl describe secret {0} | grep -E '^token' | cut -f2 -d':' | tr -d ' '".format(
                secret
            )
        ]
    )
    token = token.strip()

    return token


def main():
    try:
        module = AnsibleModule(argument_spec={}, supports_check_mode=True)
        token = handle_token()
        module.exit_json(changed=False, name=token)
    except AppException as e:
        module.fail_json(msg=str(e))


if __name__ == "__main__":
    main()
