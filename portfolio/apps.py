from django.apps import AppConfig
from django.conf import settings
from django.db.utils import OperationalError

class PortfolioConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'portfolio'

    def ready(self):
        from django.contrib.sites.models import Site
        try:
            site = Site.objects.get(pk=settings.SITE_ID)
            site.name = settings.SITE_NAME
            site.domain = settings.ALLOWED_HOSTS[0]
            site.save()
        except OperationalError:
            # 初期マイグレーションがまだ適用されていない場合は、エラーを無視します
            pass
        