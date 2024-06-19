from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _
from django_otp.plugins.otp_totp.models import TOTPDevice


class UserTOTPDevice(TOTPDevice):
    # user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.username} TOTP Device"
