from django.contrib.auth import login
from django.contrib.auth.models import User
from django.shortcuts import redirect, render


def join(request):
    if request.method == 'POST':
        # サンプルとして、デモユーザーを作成し、ログインさせる処理を実装
        # 実際の実装では、適切なユーザー登録処理を行うべきです
        user = User.objects.create_user(username='demo_user', password='demo_password')
        user.save()
        login(request, user)
        return redirect('passwordbox:dashboard')  # ダッシュボードなどのページにリダイレクト
    return render(request, 'passwordbox/join.html')
