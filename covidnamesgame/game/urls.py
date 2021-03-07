from django.urls import path
from .views import LandingView


app_name = 'game'

urlpatterns = [
    path('', LandingView.as_view(), name='landing'),
]
