import secrets
import string


def generate_secure_password(length=12, use_digits=True, use_lowercase=True, use_uppercase=True, use_special=True, banned_chars="", no_consecutive=False, exclude_similar=False):
    """
    セキュアなパスワードを生成する関数
    :param length: パスワードの長さ（デフォルトは12）
    :param use_digits: 数字を使用するかどうか（デフォルトはTrue）
    :param use_lowercase: 小文字の英字を使用するかどうか（デフォルトはTrue）
    :param use_uppercase: 大文字の英字を使用するかどうか（デフォルトはTrue）
    :param use_special: 特殊文字を使用するかどうか（デフォルトはTrue）
    :param banned_chars: 禁止文字を含む文字列
    :param no_consecutive: 連続する同じ文字を許可しない（デフォルトはFalse）
    :param exclude_similar: 見間違えやすい文字を除外（デフォルトはFalse）
    :return: 生成されたパスワード
    """
    if length < 4 or length > 4096:
        raise ValueError("Password length must be between 4 and 4096 characters")

    characters = ''
    if use_digits:
        characters += string.digits
    if use_lowercase:
        characters += string.ascii_lowercase
    if use_uppercase:
        characters += string.ascii_uppercase
    if use_special:
        characters += string.punctuation

    if exclude_similar:
        similar_chars = '0Oo1lI'
        characters = ''.join(c for c in characters if c not in similar_chars)

    characters = ''.join(c for c in characters if c not in banned_chars)

    if not characters:
        raise ValueError("At least one character set must be selected")

    while True:
        password = ''.join(secrets.choice(characters) for i in range(length))
        if no_consecutive and any(password[i] == password[i + 1] for i in range(len(password) - 1)):
            continue
        break

    return password
