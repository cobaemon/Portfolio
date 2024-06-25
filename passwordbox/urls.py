from django.urls import path

from portfolio.views import Top

from . import views

app_name = 'passwordbox'

urlpatterns = [
    path('join/', views.join, name='join'),
    path('box/', Top.as_view(), name='box'),
]
