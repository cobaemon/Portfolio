from config.settings.base import *

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

# Security settings
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
AWS_S3_CUSTOM_DOMAIN = os.environ.get('AWS_S3_CUSTOM_DOMAIN')

STATIC_LOCATION = os.environ.get('STATIC_LOCATION')
STATIC_URL = os.environ.get('STATIC_URL')
STATICFILES_STORAGE = os.environ.get('STATICFILES_STORAGE')

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
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'Portfolio/logs/debug.log'),
            'formatter': 'verbose',
        },
        'file_info': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'Portfolio/logs/info.log'),
            'formatter': 'verbose',
        },
        'file_warning': {
            'level': 'WARNING',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'Portfolio/logs/warning.log'),
            'formatter': 'verbose',
        },
        'file_error': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'Portfolio/logs/error.log'),
            'formatter': 'verbose',
        },
        'file_critical': {
            'level': 'CRITICAL',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'Portfolio/logs/critical.log'),
            'formatter': 'verbose',
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
