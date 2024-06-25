import uuid

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.db.models import Q


class Service(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    name = models.CharField(
        unique=True,
        max_length=128,
        blank=False,
        null=False
    )
    description = models.TextField(
        max_length=16384,
        blank=True,
        null=True,
    )

    def __str__(self):
        return self.name


class FixedPlan(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='fixed_plans'
    )
    name = models.CharField(
        max_length=128,
        blank=False,
        null=False
    )
    description = models.TextField(
        max_length=16384,
        blank=True,
        null=True,
    )
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=False,
        null=False
    )  # 固定料金
    duration_years = models.IntegerField(
        default=0,
        blank=False,
        null=False,
        validators=[MinValueValidator(0), MaxValueValidator(10)],
    )  # プランの期間（年）
    duration_months = models.IntegerField(
        default=1,
        blank=False,
        null=False,
        validators=[MinValueValidator(0), MaxValueValidator(12)],
    )  # プランの期間（月）
    duration_days = models.IntegerField(
        default=0,
        blank=False,
        null=False,
        validators=[MinValueValidator(0), MaxValueValidator(31)],
    )  # プランの期間（日）
    is_unlimited = models.BooleanField(
        default=False
    )  # 無期限を示すフラグ

    def __str__(self):
        return f"{self.name} ({self.service.name})"


class MeteredPlan(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='metered_plans'
    )
    name = models.CharField(
        max_length=128,
        blank=False,
        null=False
    )
    description = models.TextField(
        max_length=16384,
        blank=True,
        null=True,
    )
    base_price = models.DecimalField(
        max_digits=8,
        decimal_places=2
    )  # 基本料金

    def __str__(self):
        return f"{self.name} ({self.service.name})"


class MeteredTrigger(models.Model):
    UNIT_CHOICES = [
        ('request', 'Request'),
        ('column', 'Column'),
        ('gb', 'Gigabyte'),
        ('message', 'Message'),
    ]
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    plan = models.ForeignKey(
        MeteredPlan,
        on_delete=models.CASCADE,
        related_name='triggers'
    )
    name = models.CharField(
        max_length=128,
        blank=False,
        null=False
    )  # トリガー項目名（例: "box", "message"）
    unit_price = models.DecimalField(
        max_digits=8,
        decimal_places=2
    )
    billing_unit = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=1
    )  # 課金単位フィールド
    unit = models.CharField(
        max_length=64,
        choices=UNIT_CHOICES
    )

    def __str__(self):
        return f"{self.name} ({self.plan.name})"


class MeteredUsage(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    subscription = models.ForeignKey(
        'Subscription',
        on_delete=models.CASCADE,
        related_name='usages'
    )
    trigger = models.ForeignKey(
        MeteredTrigger,
        on_delete=models.CASCADE,
        related_name='usages'
    )
    quantity = models.DecimalField(
        max_digits=32,
        decimal_places=2,
        default=0
    )

    def __str__(self):
        return f"{self.subscription.user.username} - {self.trigger.name} ({self.quantity})"


class Subscription(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='subscriptions'
    )
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='subscriptions'
    )
    fixed_plan = models.ForeignKey(
        FixedPlan,
        null=True,
        blank=True,
        on_delete=models.CASCADE
    )
    metered_plan = models.ForeignKey(
        MeteredPlan,
        null=True,
        blank=True,
        on_delete=models.CASCADE
    )
    start_date = models.DateTimeField(auto_now_add=True)
    end_date = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'service'],
                name='unique_user_service_subscription',
                condition=Q(fixed_plan__isnull=False) | Q(metered_plan__isnull=False)
            )
        ]

    def clean(self):
        if not self.fixed_plan and not self.metered_plan:
            raise ValidationError("Either fixed_plan or metered_plan must be set.")
        if self.fixed_plan and self.metered_plan:
            raise ValidationError("Both fixed_plan and metered_plan cannot be set simultaneously.")
        if self.fixed_plan and self.fixed_plan.service != self.service:
            raise ValidationError("Fixed plan must belong to the same service as the subscription.")
        if self.metered_plan and self.metered_plan.service != self.service:
            raise ValidationError("Metered plan must belong to the same service as the subscription.")

    def calculate_additional_charges(self):
        total_charges = 0
        if self.metered_plan:
            for usage in self.usages.all():
                total_charges += (usage.quantity / usage.trigger.billing_unit) * usage.trigger.unit_price
        return total_charges

    def calculate_total_cost(self):
        total_cost = 0
        if self.fixed_plan:
            total_cost += self.fixed_plan.price
        if self.metered_plan:
            total_cost += self.metered_plan.base_price
            total_cost += self.calculate_additional_charges()
        return total_cost

    def __str__(self):
        plan_name = self.fixed_plan.name if self.fixed_plan else self.metered_plan.name
        return f"{self.user.username} - {plan_name} ({self.service.name})"
