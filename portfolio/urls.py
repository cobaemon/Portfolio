from django.urls import path, include

from portfolio.views import Top, set_language

app_name = 'portfolio'

urlpatterns = [
    path('setlang/', set_language, name='set_language'),
    path('top/', Top.as_view(), name='top'),
]
