#!/usr/bin/python3

from ansible.module_utils.basic import *
import subprocess

class AppException(Exception):
    pass

def execute_process(process):
    result = subprocess.run(process, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        raise AppException(result.stderr)
    
    return result.stdout

def handle_snap(module):
    result = execute_process(['snap list | grep {0} | wc -l'.format(module.params['name'])])
    snap_exists = not int(result) == 0

    if snap_exists and module.params['state'] == 'present':
        module.exit_json(changed=False)
        return

    if not snap_exists and module.params['state'] == 'absent':
        module.exit_json(changed=False)
        return

    if module.check_mode:
        module.exit_json(changed=True)
        return

    snap_verb = 'remove' if snap_exists else 'install'
    snap_classic = ' --classic' if module.params['classic'] else ''

    result = execute_process(['snap {0} {1}{2}'.format(snap_verb, module.params['name'], snap_classic)])
    module.exit_json(changed=True)

def main():

    fields = {
        'name': {'required': True, 'type': 'str'},
        'state': {'required': False, 'default': 'present', 'choices': ['present', 'absent']},
        'classic': {'required': False, 'type': 'bool'}
    }

    try:
        module = AnsibleModule(argument_spec=fields, supports_check_mode=True)
        handle_snap(module)
    except AppException as e:
        module.fail_json(msg=str(e))

if __name__ == '__main__':
    main()
