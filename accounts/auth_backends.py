from django.contrib.auth.backends import ModelBackend
from .models import CustomUser
from .utils import decrypt_secret_key

class CustomBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        try:
            user = CustomUser.objects.get(username=username)
            if user.check_password(password):
                if user.secret_key:
                    user.decrypted_secret_key = decrypt_secret_key(user.secret_key.key)
                return user
        except CustomUser.DoesNotExist:
            return None
