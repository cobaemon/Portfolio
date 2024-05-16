from django.urls import path

from portfolio import views

app_name = 'portfolio'

urlpatterns = [
    path('top/', views.top_view, name='top'),
]
