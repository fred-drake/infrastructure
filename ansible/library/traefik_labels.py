#!/usr/bin/python3

from ansible.module_utils.basic import *


def build_labels(name, domain, port, additional_labels):
    defaults = build_defaults(name, domain, port)
    labels = additional_labels.copy() if additional_labels is not None else {}
    for k in defaults:
        if k not in labels:
            labels[k] = defaults[k]

    return labels


def build_defaults(name, domain, port):
    t = "traefik"
    td = f"{t}.docker"
    thr = f"{t}.http.routers"
    ths = f"{t}.http.services"
    ns = f"{name}-secure"

    return {
        f"{t}.enable": "true",
        f"{td}.network": "traefik",
        f"{thr}.{ns}.rule": f"Host(`{name}.{domain}`)",
        f"{thr}.{ns}.tls": "true",
        f"{ths}.{ns}.loadbalancer.server.port": str(port),
    }


def main():

    fields = {
        "name": {"require": True, "type": "str"},
        "domain": {"require": True, "type": "str"},
        "port": {"require": True, "type": "int"},
        "additional_labels": {"required": False, "type": "map"},
    }

    module = AnsibleModule(argument_spec=fields, supports_check_mode=True)

    labels = build_labels(
        name=module.params["name"],
        domain=module.params["domain"],
        port=module.params["port"],
        additional_labels=module.params["additional_labels"],
    )

    module.exit_json(changed=False, labels=labels)


if __name__ == "__main__":
    main()
