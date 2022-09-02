#!/usr/bin/python3

from ansible.module_utils.basic import AnsibleModule
import subprocess
from os import path


class AppException(Exception):
    pass


def execute_process(process, shell=False):
    result = subprocess.run(
        process, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if result.returncode != 0:
        raise AppException(result.stderr)

    return result.stdout


def handle_feature(module):
    k3s_exists = path.exists("/usr/local/bin/k3s")
    if k3s_exists and module.params["state"] == "absent":
        if module.check_mode:
            module.exit_json(changed=True)
            return

        master_exec = "/usr/local/bin/k3s-uninstall.sh"
        agent_exec = "/usr/local/bin/k3s-agent-uninstall.sh"
        if path.exists(master_exec):
            execute_process(master_exec)
            module.exit_json(changed=True)
            return
        if path.exists(agent_exec):
            execute_process(agent_exec)
            module.exit_json(changed=True)
            return

        module.fail_json("k3s binary exists, but cannot find any uninstall scripts")
        return

    if k3s_exists and module.params["state"] == "present":
        # Already installed, nothing to do here
        module.exit_json(changed=False)
        return

    if not k3s_exists and module.params["state"] == "absent":
        # Already not installed, nothing to do here
        module.exit_json(changed=False)
        return

    # install k3s, but as master or worker?
    url = ""
    token = ""
    executable = "sh -s - --disable servicelb"
    for param in ["server_url", "token"]:
        if module.params["role"] == "worker" and not module.params[param]:
            module.fail_json(
                "if role is set to worker, {0} must be defined!".format(param)
            )
            return

    if module.params["role"] == "worker":
        url = " K3S_URL={0}".format(module.params["server_url"])
        token = " K3S_TOKEN={0}".format(module.params["token"])
        executable = "sh -"

    if module.check_mode:
        module.exit_json(changed=True)
        return

    execute_process(
        ["curl -sfL https://get.k3s.io |{0}{1} {2}".format(url, token, executable)],
        shell=True,
    )
    module.exit_json(changed=True)


def main():

    fields = {
        "state": {
            "required": False,
            "default": "present",
            "choices": ["present", "absent"],
        },
        "role": {
            "required": False,
            "default": "master",
            "choices": ["master", "worker"],
        },
        "server_url": {"required": False, "type": "str"},
        "token": {"required": False, "type": "str"},
    }

    module = AnsibleModule(argument_spec=fields, supports_check_mode=True)
    try:
        handle_feature(module)
    except AppException as e:
        module.fail_json(msg=str(e))


if __name__ == "__main__":
    main()
