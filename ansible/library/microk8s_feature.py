#!/usr/bin/python3

from ansible.module_utils.basic import AnsibleModule
import re
import subprocess


class AppException(Exception):
    pass


def execute_process(process):
    result = subprocess.run(
        process, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if result.returncode != 0:
        raise AppException(result.stderr)

    return result.stdout


def handle_feature(module, feature_name, feature_enabled, args):
    result = execute_process(["microk8s", "status", "--format", "short"])
    feature_currently_enabled = False
    feature_exists = False
    for line in result.splitlines():
        m = re.search("^{0}: (disabled|enabled)".format(feature_name), line)
        if m:
            feature_exists = True
            feature_currently_enabled = True if m.group(1) == "enabled" else False
            break

    if not feature_exists:
        module.fail_json(
            "Feature '{0}' does not exist in microk8s".format(feature_name)
        )
        return

    if feature_enabled == feature_currently_enabled:
        module.exit_json(changed=False)
        return

    if module.check_mode:
        module.exit_json(changed=True)
        return

    command = "enable" if feature_enabled else "disable"
    try:
        exec_list = ["microk8s", command, feature_name]
        if args:
            exec_list.extend(args)
        result = subprocess.check_call(exec_list)
        module.exit_json(changed=True)
    except subprocess.CalledProcessError as e:
        module.fail_json(msg=str(e))


def main():

    fields = {
        "name": {"required": True, "type": "str"},
        "enabled": {"required": False, "default": True, "type": "bool"},
        "args": {"required": False, "type": "list"},
    }

    module = AnsibleModule(argument_spec=fields, supports_check_mode=True)
    try:
        handle_feature(
            module,
            feature_name=module.params["name"],
            feature_enabled=module.params["enabled"],
            args=module.params["args"],
        )
    except AppException as e:
        module.fail_json(msg="uh oh, {0}".format(e))


if __name__ == "__main__":
    main()
