#!/bin/bash
ansible-playbook -i hosts -v --limit production provision.yml
