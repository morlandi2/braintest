#!/bin/bash
source {{django.virtualenv}}/bin/activate
export DJANGO_SETTINGS_MODULE={{django.project}}.settings.local
cd {{django.root}}/{{django.project}}
echo 'PYTHON:' `which python`
echo 'SETTINGS:' $DJANGO_SETTINGS_MODULE
