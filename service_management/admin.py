from django.contrib import admin

from .models import (FixedPlan, MeteredPlan, MeteredTrigger, MeteredUsage,
                     Service, Subscription)


class SubscriptionAdmin(admin.ModelAdmin):
    def save_model(self, request, obj, form, change):
        obj.clean()  # モデルのクリーンメソッドを呼び出してバリデーションを実行
        super().save_model(request, obj, form, change)

admin.site.register(Service)
admin.site.register(FixedPlan)
admin.site.register(MeteredPlan)
admin.site.register(MeteredTrigger)
admin.site.register(MeteredUsage)
admin.site.register(Subscription, SubscriptionAdmin)
