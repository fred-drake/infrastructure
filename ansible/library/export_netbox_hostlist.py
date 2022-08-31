#!/usr/bin/python3

from ansible.module_utils.basic import *
import urllib.parse, urllib.request
import json

def build_hosts(token, api_prefix, tag):
    offset = 0
    limit = 50
    url = '{0}/api/ipam/ip-addresses/'.format(api_prefix)
    headers = {'Authorization': 'Token {0}'.format(token)}

    hosts = []
    while True:
        params = urllib.parse.urlencode({'offset': offset, 'limit': limit})
        request = urllib.request.Request(url='{0}?{1}'.format(url, params), headers=headers)
        response = urllib.request.urlopen(url=request)
        response = json.load(response)
        
        for result in response['results']:
            address = result['address'].split('/')[0]

            if tag is not None:
                for t in result['tags']:
                    if t['name'] == tag: 
                        add_host(hosts, address, result['dns_name'])
                        continue
                continue

            if result['status']['value'] not in ['active', 'reserved']:
                continue

            if result['dns_name']:
                add_host(hosts, address, result['dns_name'])

            for t in result['tags']:
                if not t['name'].startswith('dnsalias:'):
                    continue
                
                hostname = t['name'].split(':')[1]
                add_host(hosts, address, hostname)

        if not response['next']:
            break

        offset += 50

    return hosts

def add_host(hosts, address, hostname):
    hosts.append({ 'address': address, 'hostname': hostname })
    return

def main():
    
    fields = {
        'netbox_token': {'required': True, 'type': 'str'},
        'netbox_api_prefix': {'required': True, 'type': 'str'},
        'tag': {'required': False, 'type': 'str'},
    }

    module = AnsibleModule(argument_spec=fields, supports_check_mode=True)

    hosts = build_hosts(token=module.params['netbox_token'], api_prefix=module.params['netbox_api_prefix'], tag=module.params['tag'])

    module.exit_json(changed=False, hosts=hosts)

if __name__ == '__main__':
    main()
