from braintest.settings.production import *

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': '{{database.db_name}}',
        'USER': '{{database.db_user}}',
        'PASSWORD': '{{database.db_password}}',
        'HOST': '127.0.0.1',
        'PORT': '5432',
    }
}
