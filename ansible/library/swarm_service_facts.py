#!/usr/bin/python3

from ansible.module_utils.basic import AnsibleModule


def build_facts(
    domain,
    cifs_server,
    nfs_server,
    nfs_mount_options,
    cifs_mount_options,
    glusterfs_appdata_dir,
    service,
):
    sf = {}
    sf["name"] = service["name"]
    sf["service_network"] = len(service["containers"]) > 1 or (
        "backup" in service and service["backup"]
    )
    sf["networks"] = set()
    sf["bind_mount_source_paths"] = set()
    sf["services"] = []

    for container in service["containers"]:
        pod = {}
        if "name" not in container and len(service["containers"]) > 1:
            raise Exception(
                "Container name is not defined but we have multiple containers."
            )
        pod["name"] = container["name"] if "name" in container else service["name"]
        pod["repository"] = container["repository"]
        pod["tag"] = container["tag"]

        if "command" in container:
            pod["command"] = container["command"]

        if "mode" in container:
            pod["mode"] = container["mode"]

        pod["constraints"] = (
            container["constraints"] if "constraints" in container else []
        )
        add_default_constraint = True
        for c in pod["constraints"]:
            if c.startswith("node.role"):
                add_default_constraint = False
        if add_default_constraint:
            pod["constraints"].append("node.role==worker")

        if "publish" in container:
            pod["publish"] = container["publish"]

        if "endpoint_mode" in container:
            pod["endpoint_mode"] = container["endpoint_mode"]

        pod["networks"] = []
        if "web_port" in container:
            pod["networks"].append("traefik")
            sf["networks"].add("traefik")
        if sf["service_network"]:
            pod["networks"].append(sf["name"])
            sf["networks"].add(sf["name"])

        if "networks" in container:
            for nw in container["networks"]:
                pod["networks"].append(nw)

        container_labels = container["labels"] if "labels" in container else {}
        if "web_port" in container:
            if "web_hostname" in container:
                hostname = container["web_hostname"]
            elif "name" in container:
                hostname = container["name"]
            else:
                hostname = service["name"]
            pod["labels"] = build_labels(
                pod["name"],
                hostname,
                domain,
                container["web_port"],
                container_labels,
            )
        else:
            pod["labels"] = container_labels

        pod["mounts"] = []
        if "bind_mounts" in container:
            for bm in container["bind_mounts"]:
                mount = {}
                mount["target"] = bm["target"]
                mount["type"] = "bind"
                if "literal" in bm and bm["literal"] is True:
                    mount["source"] = bm["source"]
                else:
                    mount[
                        "source"
                    ] = f"{glusterfs_appdata_dir}/{sf['name']}/{pod['name']}/{bm['source']}"
                    if "type" not in bm or bm["type"] == "directory":
                        sf["bind_mount_source_paths"].add(mount["source"])
                if "readonly" in bm:
                    mount["readonly"] = bm["readonly"]
                pod["mounts"].append(mount)
        if "cifs_mounts" in container:
            for cm in container["cifs_mounts"]:
                device_share = (
                    cm["device_share"] if "device_share" in cm else cm["name"]
                )
                mount = {}
                mount["type"] = "volume"
                mount["source"] = f"{pod['name']}_{cm['name']}"
                mount["target"] = cm["target"]
                mount["driver_config"] = {}
                mount["driver_config"]["name"] = "local"
                mount["driver_config"]["options"] = {}
                mount["driver_config"]["options"]["type"] = "cifs"
                mount["driver_config"]["options"][
                    "device"
                ] = f"//{cifs_server}/{device_share}"

                if "mount_options" in cm:
                    mount["driver_config"]["options"][
                        "o"
                    ] = f"{cifs_mount_options},{cm['mount_options']}"
                else:
                    mount["driver_config"]["options"]["o"] = cifs_mount_options
                pod["mounts"].append(mount)
        if "nfs_mounts" in container:
            for nm in container["nfs_mounts"]:
                device_share = (
                    nm["device_share"] if "device_share" in nm else nm["name"]
                )
                mount = {}
                mount["type"] = "volume"
                mount["source"] = f"{pod['name']}_{nm['name']}"
                mount["target"] = nm["target"]
                mount["driver_config"] = {}
                mount["driver_config"]["name"] = "local"
                mount["driver_config"]["options"] = {}
                mount["driver_config"]["options"]["type"] = "nfs"
                mount["driver_config"]["options"]["device"] = f":/{device_share}"
                mount["driver_config"]["options"][
                    "o"
                ] = f"addr={nfs_server},{nfs_mount_options}"
                if "mount_options" in nm:
                    mount["driver_config"]["options"]["o"] += f",{nm['mount_options']}"
                pod["mounts"].append(mount)
        if "env" in container:
            pod["env"] = container["env"]
        sf["services"].append(pod)

    return sf


def build_labels(name, hostname, domain, port, additional_labels):
    defaults = build_defaults(name, hostname, domain, port)
    labels = additional_labels.copy() if additional_labels is not None else {}
    for k in defaults:
        if k not in labels:
            labels[k] = defaults[k]

    return labels


def build_defaults(name, hostname, domain, port):
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
        f"{thr}.{name}.rule": f"Host(`{hostname}.{domain}`)",
        f"{thm}.{name}-https-redirect.redirectscheme.scheme": "https",
        f"{thm}.sslheader.headers.customrequestheaders.X-Forwarded-Proto": "https",
        f"{thr}.{name}.middlewares": f"{name}-https-redirect",
        f"{thr}.{ns}.entrypoints": "https",
        f"{thr}.{ns}.rule": f"Host(`{hostname}.{domain}`)",
        f"{thr}.{ns}.tls": "true",
        f"{thr}.{ns}.tls.certresolver": "cloudflare",
        f"{thr}.{ns}.tls.domains[0].main": domain,
        f"{thr}.{ns}.tls.domains[0].sans": f"*.{domain}",
        f"{thr}.{ns}.service": name,
        f"{ths}.{name}.loadbalancer.server.port": str(port),
    }


def main():

    fields = {
        "domain": {"require": True, "type": "str"},
        "cifs_server": {"require": True, "type": "str"},
        "cifs_mount_options": {"require": True, "type": "str"},
        "nfs_server": {"require": True, "type": "str"},
        "nfs_mount_options": {"require": True, "type": "str"},
        "glusterfs_appdata_dir": {"require": True, "type": "str"},
        "service": {"require": True, "type": "dict"},
    }

    module = AnsibleModule(argument_spec=fields, supports_check_mode=True)

    try:
        facts = build_facts(
            domain=module.params["domain"],
            cifs_server=module.params["cifs_server"],
            cifs_mount_options=module.params["cifs_mount_options"],
            nfs_server=module.params["nfs_server"],
            nfs_mount_options=module.params["nfs_mount_options"],
            glusterfs_appdata_dir=module.params["glusterfs_appdata_dir"],
            service=module.params["service"],
        )

        module.exit_json(changed=False, facts=facts)
    except Exception as err:
        module.fail_json(msg=err)


if __name__ == "__main__":
    main()
