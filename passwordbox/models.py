import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone

from accounts.utils import (decrypt_secret_key, decrypt_user_data,
                            encrypt_user_data)


class Box(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    user = models.ForeignKey(
        getattr(settings, 'AUTH_USER_MODEL', 'auth.User'),
        help_text="The user that this box belongs to.",
        on_delete=models.CASCADE,
    )
    name = models.CharField(
        max_length=64,
        blank=False,
        help_text="The human-readable name of this box."
    )

    service_url = models.URLField(
        blank=True,
        help_text="The URL of the service associated with this credential."
    )
    username = models.BinaryField(
        blank=True,
        max_length=80
    )
    email = models.BinaryField(
        blank=True,
        max_length=272
    )
    password = models.BinaryField(
        blank=False,
        max_length=4112
    )
    password_last_updated = models.DateTimeField(
        default=timezone.now,
        help_text="The date and time when the password was last updated."
    )
    two_factor_info = models.BinaryField(
        blank=True,
        max_length=512,
        help_text="Information related to two-factor authentication."
    )
    security_question = models.CharField(
        max_length=255,
        blank=True,
        help_text="Security question associated with this credential."
    )
    security_answer = models.BinaryField(
        blank=True,
        max_length=255,
        help_text="Encrypted answer to the security question."
    )
    notes = models.BinaryField(
        blank=True,
        help_text="Encrypted additional notes or comments about this credential."
    )
    description = models.CharField(
        blank=True,
        max_length=256
    )
    date_joined = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")

        secret_key = decrypt_secret_key(secret_key_instance.key)

        if isinstance(self.username, str):
            self.username = encrypt_user_data(self.username, secret_key)
        if isinstance(self.email, str):
            self.email = encrypt_user_data(self.email, secret_key)
        if isinstance(self.password, str):
            self.password = encrypt_user_data(self.password, secret_key)
        if isinstance(self.security_answer, str):
            self.security_answer = encrypt_user_data(self.security_answer, secret_key)
        if isinstance(self.two_factor_info, str):
            self.two_factor_info = encrypt_user_data(self.two_factor_info, secret_key)
        if isinstance(self.notes, str):
            self.notes = encrypt_user_data(self.notes, secret_key)

        super().save(*args, **kwargs)

    def get_username(self):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")
        secret_key = decrypt_secret_key(secret_key_instance.key)
        return decrypt_user_data(self.username, secret_key)

    def get_email(self):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")
        secret_key = decrypt_secret_key(secret_key_instance.key)
        return decrypt_user_data(self.email, secret_key)

    def get_password(self):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")
        secret_key = decrypt_secret_key(secret_key_instance.key)
        return decrypt_user_data(self.password, secret_key)

    def get_security_answer(self):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")
        secret_key = decrypt_secret_key(secret_key_instance.key)
        return decrypt_user_data(self.security_answer, secret_key)

    def get_two_factor_info(self):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")
        secret_key = decrypt_secret_key(secret_key_instance.key)
        return decrypt_user_data(self.two_factor_info, secret_key)

    def get_notes(self):
        secret_key_instance = self.user.secret_key
        if not secret_key_instance or not secret_key_instance.is_valid():
            raise ValueError("Invalid or missing secret key for user.")
        secret_key = decrypt_secret_key(secret_key_instance.key)
        return decrypt_user_data(self.notes, secret_key)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'name'], name='unique_user_name')
        ]

    def __str__(self):
        return self.name
