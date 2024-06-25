from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render
from django.utils import timezone

from .models import (FixedPlan, MeteredPlan, MeteredTrigger, Service,
                     Subscription, SubscriptionHistory)


@login_required
def join_service(request, service_id):
    service = Service.objects.get(id=service_id)
    fixed_plans = service.fixed_plans.all()
    metered_plans = service.metered_plans.all()

    if request.method == 'POST':
        plan_type = request.POST.get('plan_type')
        plan_id = request.POST.get('plan_id')
        user = request.user

        # 現在のアクティブなサブスクリプションを無効にし、履歴に保存
        active_subscriptions = Subscription.objects.filter(user=user, service=service, is_active=True)
        for subscription in active_subscriptions:
            subscription.is_active = False
            subscription.end_date = timezone.now()
            subscription.save()
            SubscriptionHistory.objects.create(
                user=user,
                service=subscription.service,
                start_date=subscription.start_date,
                end_date=subscription.end_date,
                fixed_plan=subscription.fixed_plan,
                metered_plan=subscription.metered_plan
            )

        if plan_type == 'fixed':
            fixed_plan = FixedPlan.objects.get(id=plan_id)
            end_date = timezone.now() + timezone.timedelta(days=fixed_plan.duration_days)
            Subscription.objects.create(user=user, service=service, fixed_plan=fixed_plan, end_date=end_date)
        elif plan_type == 'metered':
            metered_plan = MeteredPlan.objects.get(id=plan_id)
            Subscription.objects.create(user=user, service=service, metered_plan=metered_plan)

        return redirect('service_management:service_detail', service_id=service.id)

    return render(request, 'service_management/join_service.html', {'service': service, 'fixed_plans': fixed_plans, 'metered_plans': metered_plans})

@login_required
def manage_subscription(request, subscription_id):
    subscription = Subscription.objects.get(id=subscription_id, user=request.user)

    if request.method == 'POST':
        trigger_name = request.POST.get('trigger_name')
        additional_units = int(request.POST.get('additional_units', 0))
        if trigger_name and additional_units > 0:
            subscription.additional_units[trigger_name] = subscription.additional_units.get(trigger_name, 0) + additional_units
            subscription.calculate_additional_charges()
            subscription.save()
        return redirect('service_management:subscription_detail', subscription_id=subscription.id)

    triggers = subscription.metered_plan.triggers.all() if subscription.metered_plan else []
    return render(request, 'service_management/manage_subscription.html', {'subscription': subscription, 'triggers': triggers})
