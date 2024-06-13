from allauth.account.adapter import DefaultAccountAdapter
from django.core.mail import send_mail
from django.utils import timezone
from django.conf import settings
from .models import LoginCode
import secrets
import string

class CustomAccountAdapter(DefaultAccountAdapter):
    def send_login_code(self, user):
        code = self.generate_login_code()
        expiration = timezone.now() + timezone.timedelta(minutes=10)

        # LoginCodeモデルに保存
        LoginCode.objects.create(user=user, code=code, expires_at=expiration)

        # メール送信
        subject = 'Your Login Code'
        message = f'Your login code is {code}. It will expire in 10 minutes.'
        email_from = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]
        send_mail(subject, message, email_from, recipient_list)

    def generate_login_code(self):
        return ''.join(secrets.choice(string.digits) for i in range(6))
