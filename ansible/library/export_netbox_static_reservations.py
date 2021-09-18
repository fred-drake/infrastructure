#!/usr/bin/python

from ansible.module_utils.basic import *
import urllib.parse, urllib.request
import json
import ipaddress

class AppException(Exception):
    pass

def build_reservations(token, api_prefix, subnet_dict):
    offset = 0
    limit = 50
    url = '{0}/api/ipam/ip-addresses/'.format(api_prefix)
    headers = {'Authorization': 'Token {0}'.format(token)}

    # Calculate netmasks upfront to save time
    netmasks = {}
    for key in subnet_dict:
        n = ipaddress.ip_network('{0}/{1}'.format(subnet_dict[key]['subnet'], subnet_dict[key]['netmask']))
        netw = int(n.network_address)
        mask = int(n.netmask)
        netmasks[key] = { 'address': netw, 'mask': mask }

    reservations = {}
    while True:
        params = urllib.parse.urlencode({'offset': offset, 'limit': limit})
        request = urllib.request.Request(url='{0}?{1}'.format(url, params), headers=headers)
        response = urllib.request.urlopen(url=request)
        response = json.load(response)
        for result in response['results']:
            address = result['address'].split('/')[0]

            # Skip any IPs without the status "Reserved" in Netbox
            if result['status']['value'] != 'reserved':
                continue;

            # Needs to have a DNS name assigned
            dns_name = result['dns_name']
            if not dns_name:
                raise AppException('IP address {0} is configured in Netbox as reserved, but has no DNS name!'.format(address))

            # Needs a device and interface associated with this IP address in Netbox
            if not result['assigned_object']:
                raise AppException('IP address {0} has no device / interface assigned!'.format(address))

            interface_url = result['assigned_object']['url']
            intf_request = urllib.request.Request(url=interface_url, headers=headers)
            intf_response = urllib.request.urlopen(url=intf_request)
            intf_response = json.load(intf_response)
            mac_address = intf_response['mac_address']

            # Has a device and interface associated with this IP address, but also needs a mac address in Netbox
            if not mac_address:
                print('IP address {0} has device / interface assigned ({1}/{2}) but no mac address defined for the interface!'.format(address,
                intf_response['device']['display'], intf_response['display']))

            mac_address = mac_address.lower()

            for key in subnet_dict:
                if (int(ipaddress.ip_address(address)) & netmasks[key]['mask']) == netmasks[key]['address']:
                    if not reservations.get(key):
                        reservations[key] = []
                    reservations[key].append({ 'hostname': dns_name, 'mac_address': mac_address, 'ip_address': address })
                    continue

        if not response['next']:
            break;

        offset += 50

    return reservations

def main():
    
    fields = {
        'netbox_token': {'required': True, 'type': 'str'},
        'netbox_api_prefix': {'required': True, 'type': 'str'},
        'subnet_dict': {'required': True, 'type': 'dict'}
    }

    module = AnsibleModule(argument_spec=fields, supports_check_mode=True)

    try:
        reservations = build_reservations(token=module.params['netbox_token'], api_prefix=module.params['netbox_api_prefix'], 
        subnet_dict=module.params['subnet_dict'])

        module.exit_json(changed=False, reservations=reservations)
    except AppException as e:
        module.fail_json(msg=str(e))

if __name__ == '__main__':
    main()
