import os

apps = [
    'ai', 'analytics', 'collections', 'localization', 'notifications',
    'payments', 'platform_admin', 'ratings', 'recycling', 'reports',
    'rewards', 'routing', 'security', 'support', 'tracking', 'waste_requests'
]

for app in apps:
    class_name = ''.join(word.capitalize() for word in app.split('_'))
    content = f'''from django.apps import AppConfig


class {class_name}Config(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.{app}"
'''
    filepath = os.path.join('apps', app, 'apps.py')
    with open(filepath, 'w') as f:
        f.write(content)
    print(f'Created {filepath}')

print('Done!')
