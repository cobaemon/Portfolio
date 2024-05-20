from config.settings.base import *

SITE_ID = 1

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

ALLOWED_HOSTS = ['portfolio.cobaemon.com']

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')

# メールを実際に送る
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
# メールホスト
EMAIL_HOST = os.environ.get('EMAIL_HOST')
# ポート
EMAIL_PORT = os.environ.get('EMAIL_PORT', int)
# メールの暗号化
EMAIL_USE_TLS = True
# 送信元
EMAIL_HOST_USER = DEFAULT_FROM_EMAIL = os.environ.get('EMAIL_HOST_USER')
# パスワード
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD')
# デフォルトの送信元
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL')
# デフォルトの送信先
DEFAULT_TO_EMAIL = os.environ.get('DEFAULT_TO_EMAIL')

# CSRF設定
CSRF_TRUSTED_ORIGINS = [
    'https://portfolio.cobaemon.com'
]

# CORS設定
CORS_ALLOWED_ORIGINS = [
    'https://portfolio.cobaemon.com'
]
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = (
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
)

# セキュリティ設定
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_DOMAIN = 'portfolio.cobaemon.com'
SESSION_COOKIE_HTTPONLY = True
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
CSRF_COOKIE_NAME = 'csrftoken'
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_SAMESITE = 'None'
CSRF_USE_SESSIONS = False
CSRF_COOKIE_DOMAIN = '.cobaemon.com'
CSRF_COOKIE_HTTPONLY = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
USE_X_FORWARDED_HOST = True
USE_X_FORWARDED_PORT = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000  # 1年間
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'

LANGUAGE_COOKIE_DOMAIN = 'portfolio.cobaemon.com'
LANGUAGE_COOKIE_HTTPONLY = True
LANGUAGE_COOKIE_SECURE = True

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file_debug': {
            'level': 'DEBUG',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(BASE_DIR, 'logs/django_debug.log'),
            'formatter': 'verbose',
            'maxBytes': 1024*1024*5,  # 5MB
            'backupCount': 3,
        },
        'file_info': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(BASE_DIR, 'logs/django_info.log'),
            'formatter': 'verbose',
            'maxBytes': 1024*1024*5,  # 5MB
            'backupCount': 3,
        },
        'file_warning': {
            'level': 'WARNING',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(BASE_DIR, 'logs/django_warning.log'),
            'formatter': 'verbose',
            'maxBytes': 1024*1024*5,  # 5MB
            'backupCount': 3,
        },
        'file_error': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(BASE_DIR, 'logs/django_error.log'),
            'formatter': 'verbose',
            'maxBytes': 1024*1024*5,  # 5MB
            'backupCount': 3,
        },
        'file_critical': {
            'level': 'CRITICAL',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(BASE_DIR, 'logs/django_critical.log'),
            'formatter': 'verbose',
            'maxBytes': 1024*1024*5,  # 5MB
            'backupCount': 3,
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file_debug', 'file_info', 'file_warning', 'file_error', 'file_critical'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}