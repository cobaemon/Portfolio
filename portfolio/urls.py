from django.urls import path, include

from portfolio.views import Top

app_name = 'portfolio'

urlpatterns = [
    path('top/', Top.as_view(), name='top'),
]
