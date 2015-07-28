#!/bin/bash
#source {{django.pythonpath}}/activate
#cd {{django.website_home}}
gunicorn {{django.project}}.wsgi -c gunicorn.conf.py
