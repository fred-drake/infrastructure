#!/usr/bin/python3

from ansible.module_utils.basic import AnsibleModule


def build_labels(name, domain, port, additional_labels):
    defaults = build_defaults(name, domain, port)
    labels = additional_labels.copy() if additional_labels is not None else {}
    for k in defaults:
        if k not in labels:
            labels[k] = defaults[k]

    return labels


def build_defaults(name, domain, port):
    t = "traefik"
    thr = f"{t}.http.routers"
    ths = f"{t}.http.services"
    thm = f"{t}.http.middlewares"
    ns = f"{name}-secure"

    return {
        f"{t}.enable": "true",
        f"{t}.docker.network": "traefik",
        f"{t}.backend.loadbalancer.swarm": "true",
        f"{thr}.{name}.entrypoints": "http",
        f"{thr}.{name}.rule": f"Host(`{name}.{domain}`)",
        f"{thm}.{name}-https-redirect.redirectscheme.scheme": "https",
        f"{thm}.sslheader.headers.customrequestheaders.X-Forwarded-Proto": "https",
        f"{thr}.{name}.middlewares": f"{name}-https-redirect",
        f"{thr}.{ns}.entrypoints": "https",
        f"{thr}.{ns}.rule": f"Host(`{name}.{domain}`)",
        f"{thr}.{ns}.tls": "true",
        f"{thr}.{ns}.tls.certresolver": "cloudflare",
        f"{thr}.{ns}.tls.domains[0].main": domain,
        f"{thr}.{ns}.tls.domains[0].sans": f"*.{domain}",
        f"{thr}.{ns}.service": name,
        f"{ths}.{name}.loadbalancer.server.port": str(port),
    }


def main():

    fields = {
        "name": {"require": True, "type": "str"},
        "domain": {"require": True, "type": "str"},
        "port": {"require": True, "type": "int"},
        "additional_labels": {"required": False, "type": "dict"},
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
