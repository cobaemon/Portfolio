from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.contrib.sites.shortcuts import get_current_site
from django.core.exceptions import PermissionDenied
from django.core.validators import validate_email
from django.forms import ValidationError
from django.http import Http404, HttpResponse, HttpResponseRedirect
from django.urls import reverse, reverse_lazy
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from django.views.decorators.debug import sensitive_post_parameters
from django.views.generic.base import TemplateView
from django.views.generic.edit import FormView

from allauth.account.views import *
from allauth.account.mixins import _ajax_response
from django.contrib import messages
from django.shortcuts import redirect, render, get_object_or_404
from .forms import *
from config.settings import base as setting
from .models import CustomUser
from django.utils import timezone
from django.contrib.auth import authenticate
from allauth.account.utils import perform_login, get_login_redirect_url

from config.settings import base as settings


def add_error_messages(request, form):
    for field, errors in form.errors.items():
        # label = form.fields[field].label
        for error in errors:
            # messages.error(self.request, f'{label}: {error}')
            messages.error(request, f'{error}')


@method_decorator(rate_limit(action="login"), name="dispatch")
class LoginView(
    NextRedirectMixin,
    RedirectAuthenticatedUserMixin,
    AjaxCapableProcessFormViewMixin,
    FormView,
):
    form_class = LoginForm
    template_name = "account/login." + app_settings.TEMPLATE_EXTENSION
    success_url = None

    @sensitive_post_parameters_m
    @method_decorator(never_cache)
    def dispatch(self, request, *args, **kwargs):
        if allauth_app_settings.SOCIALACCOUNT_ONLY and request.method != "GET":
            raise PermissionDenied()
        return super().dispatch(request, *args, **kwargs)

    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs["request"] = self.request
        return kwargs

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "login", self.form_class)

    def form_valid(self, form):
        credentials = form.cleaned_data
        email = credentials.get('login')
        password = credentials.get('password')
        
        user = authenticate(username=email, password=password)
        
        if user and user.use_login_by_code:
            next_url = self.request.GET.get('next')
            if next_url:
                self.request.session['next'] = next_url
            flows.login_by_code.request_login_code(self.request, email)
            return redirect('account_confirm_login_code')
        
        # 通常のログイン処理
        redirect_url = self.get_success_url()
        try:
            return form.login(self.request, redirect_url=redirect_url)
        except ImmediateHttpResponse as e:
            return e.response
        
    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response

    def get_context_data(self, **kwargs):
        ret = super().get_context_data(**kwargs)
        signup_url = None
        if not allauth_app_settings.SOCIALACCOUNT_ONLY:
            signup_url = self.passthrough_next_url(reverse("account_signup"))
        site = get_current_site(self.request)

        ret.update(
            {
                "signup_url": signup_url,
                "site": site,
                "SOCIALACCOUNT_ENABLED": allauth_app_settings.SOCIALACCOUNT_ENABLED,
                "SOCIALACCOUNT_ONLY": allauth_app_settings.SOCIALACCOUNT_ONLY,
                "LOGIN_BY_CODE_ENABLED": app_settings.LOGIN_BY_CODE_ENABLED,
            }
        )
        if app_settings.LOGIN_BY_CODE_ENABLED:
            request_login_code_url = self.passthrough_next_url(
                reverse("account_request_login_code")
            )
            ret["request_login_code_url"] = request_login_code_url
        return ret


@method_decorator(rate_limit(action="signup"), name="dispatch")
class SignupView(
    RedirectAuthenticatedUserMixin,
    CloseableSignupMixin,
    NextRedirectMixin,
    AjaxCapableProcessFormViewMixin,
    FormView,
):
    template_name = "account/signup." + app_settings.TEMPLATE_EXTENSION
    form_class = SignupForm

    @sensitive_post_parameters_m
    @method_decorator(never_cache)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "signup", self.form_class)

    def form_valid(self, form):
        self.user, resp = form.try_save(self.request)
        if resp:
            return resp
        try:
            redirect_url = self.get_success_url()
            return complete_signup(
                self.request,
                self.user,
                email_verification=None,
                success_url=redirect_url,
            )
        except ImmediateHttpResponse as e:
            return e.response

    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response

    def get_context_data(self, **kwargs):
        ret = super().get_context_data(**kwargs)
        form = ret["form"]
        email = self.request.session.get("account_verified_email")
        if email:
            email_keys = ["email"]
            if app_settings.SIGNUP_EMAIL_ENTER_TWICE:
                email_keys.append("email2")
            for email_key in email_keys:
                form.fields[email_key].initial = email
        login_url = self.passthrough_next_url(reverse("account_login"))
        site = get_current_site(self.request)
        ret.update(
            {
                "login_url": login_url,
                "site": site,
                "SOCIALACCOUNT_ENABLED": allauth_app_settings.SOCIALACCOUNT_ENABLED,
                "SOCIALACCOUNT_ONLY": allauth_app_settings.SOCIALACCOUNT_ONLY,
            }
        )
        return ret

    def get_initial(self):
        initial = super().get_initial()
        email = self.request.GET.get("email")
        if email:
            try:
                validate_email(email)
            except ValidationError:
                return initial
            initial["email"] = email
            if app_settings.SIGNUP_EMAIL_ENTER_TWICE:
                initial["email2"] = email
        return initial


class PasswordResetView(NextRedirectMixin, AjaxCapableProcessFormViewMixin, FormView):
    template_name = "account/password_reset." + app_settings.TEMPLATE_EXTENSION
    form_class = ResetPasswordForm
    success_url = reverse_lazy("account_reset_password_done")

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "reset_password", self.form_class)

    def form_valid(self, form):
        r429 = ratelimit.consume_or_429(
            self.request,
            action="reset_password",
            key=form.cleaned_data["email"].lower(),
        )
        if r429:
            return r429
        form.save(self.request)
        return super().form_valid(form)

    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response

    def get_context_data(self, **kwargs):
        ret = super().get_context_data(**kwargs)
        login_url = self.passthrough_next_url(reverse("account_login"))
        # NOTE: For backwards compatibility
        ret["password_reset_form"] = ret.get("form")
        # (end NOTE)
        ret.update({"login_url": login_url})
        return ret


@method_decorator(rate_limit(action="reset_password_from_key"), name="dispatch")
class PasswordResetFromKeyView(
    AjaxCapableProcessFormViewMixin,
    NextRedirectMixin,
    LogoutFunctionalityMixin,
    FormView,
):
    template_name = "account/password_reset_from_key." + app_settings.TEMPLATE_EXTENSION
    form_class = ResetPasswordKeyForm
    success_url = reverse_lazy("account_reset_password_from_key_done")
    reset_url_key = "set-password"

    def get_form_class(self):
        return get_form_class(
            app_settings.FORMS, "reset_password_from_key", self.form_class
        )

    def dispatch(self, request, uidb36, key, **kwargs):
        self.request = request
        self.key = key

        user_token_form_class = get_form_class(
            app_settings.FORMS, "user_token", UserTokenForm
        )
        is_ajax = get_adapter().is_ajax(request)
        if self.key == self.reset_url_key or is_ajax:
            if not is_ajax:
                self.key = self.request.session.get(INTERNAL_RESET_SESSION_KEY, "")
            # (Ab)using forms here to be able to handle errors in XHR #890
            token_form = user_token_form_class(data={"uidb36": uidb36, "key": self.key})
            if token_form.is_valid():
                self.reset_user = token_form.reset_user

                # In the event someone clicks on a password reset link
                # for one account while logged into another account,
                # logout of the currently logged in account.
                if (
                    self.request.user.is_authenticated
                    and self.request.user.pk != self.reset_user.pk
                ):
                    self.logout()
                    self.request.session[INTERNAL_RESET_SESSION_KEY] = self.key

                return super().dispatch(request, uidb36, self.key, **kwargs)
        else:
            token_form = user_token_form_class(data={"uidb36": uidb36, "key": self.key})
            if token_form.is_valid():
                # Store the key in the session and redirect to the
                # password reset form at a URL without the key. That
                # avoids the possibility of leaking the key in the
                # HTTP Referer header.
                self.request.session[INTERNAL_RESET_SESSION_KEY] = self.key
                redirect_url = self.passthrough_next_url(
                    self.request.path.replace(self.key, self.reset_url_key)
                )
                return redirect(redirect_url)

        self.reset_user = None
        response = self.render_to_response(self.get_context_data(token_fail=True))
        return _ajax_response(self.request, response, form=token_form)

    def get_context_data(self, **kwargs):
        ret = super(PasswordResetFromKeyView, self).get_context_data(**kwargs)
        ret["action_url"] = reverse(
            "account_reset_password_from_key",
            kwargs={
                "uidb36": self.kwargs["uidb36"],
                "key": self.kwargs["key"],
            },
        )
        return ret

    def get_form_kwargs(self):
        kwargs = super(PasswordResetFromKeyView, self).get_form_kwargs()
        kwargs["user"] = self.reset_user
        kwargs["temp_key"] = self.key
        return kwargs

    def form_valid(self, form):
        form.save()
        flows.password_reset.finalize_password_reset(self.request, self.reset_user)
        if app_settings.LOGIN_ON_PASSWORD_RESET:
            return perform_login(
                self.request,
                self.reset_user,
            )
        return super(PasswordResetFromKeyView, self).form_valid(form)

    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response


@method_decorator(login_required, name="dispatch")
@method_decorator(rate_limit(action="change_password"), name="dispatch")
class PasswordChangeView(AjaxCapableProcessFormViewMixin, NextRedirectMixin, FormView):
    template_name = "account/password_change." + app_settings.TEMPLATE_EXTENSION
    form_class = ChangePasswordForm

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "change_password", self.form_class)

    @sensitive_post_parameters_m
    def dispatch(self, request, *args, **kwargs):
        if not self.request.user.has_usable_password():
            return HttpResponseRedirect(reverse("account_set_password"))
        return super().dispatch(request, *args, **kwargs)

    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs["user"] = self.request.user
        return kwargs

    def get_default_success_url(self):
        return get_adapter().get_password_change_redirect_url(self.request)

    def form_valid(self, form):
        form.save()
        flows.password_change.finalize_password_change(self.request, form.user)
        return super().form_valid(form)

    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response

    def get_context_data(self, **kwargs):
        ret = super().get_context_data(**kwargs)
        # NOTE: For backwards compatibility
        ret["password_change_form"] = ret.get("form")
        # (end NOTE)
        return ret


@method_decorator(login_required, name="dispatch")
class ReauthenticateView(BaseReauthenticateView):
    form_class = ReauthenticateForm
    template_name = "account/reauthenticate." + app_settings.TEMPLATE_EXTENSION

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "reauthenticate", self.form_class)

    def get_form_kwargs(self):
        ret = super().get_form_kwargs()
        ret["user"] = self.request.user
        return ret

    def form_valid(self, form):
        flows.reauthentication.reauthenticate_by_password(self.request)
        return super().form_valid(form)

    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response


@method_decorator(login_required, name="dispatch")
@method_decorator(rate_limit(action="manage_email"), name="dispatch")
class EmailView(AjaxCapableProcessFormViewMixin, FormView):
    template_name = (
        "account/email_change." if app_settings.CHANGE_EMAIL else "account/email."
    ) + app_settings.TEMPLATE_EXTENSION
    form_class = AddEmailForm
    success_url = reverse_lazy("account_email")

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "add_email", self.form_class)

    def dispatch(self, request, *args, **kwargs):
        sync_user_email_addresses(request.user)
        return super().dispatch(request, *args, **kwargs)

    def get_form_kwargs(self):
        kwargs = super(EmailView, self).get_form_kwargs()
        kwargs["user"] = self.request.user
        return kwargs

    def form_valid(self, form):
        flows.manage_email.add_email(self.request, form)
        return super().form_valid(form)
    
    def form_invalid(self, form):
        response = super().form_invalid(form)
        add_error_messages(self.request, form)
        return response

    def post(self, request, *args, **kwargs):
        res = None
        if "action_add" in request.POST:
            res = super(EmailView, self).post(request, *args, **kwargs)
        elif request.POST.get("email"):
            email_address = EmailAddress.objects.filter(email=request.POST["email"], user=request.user).first()
            if "action_send" in request.POST:
                if email_address.verified:
                    messages.info(request, 'This email address has already been verified.')
                res = self._action_send(request)
            elif "action_remove" in request.POST:
                res = self._action_remove(request)
            elif "action_primary" in request.POST:
                res = self._action_primary(request)
            res = res or HttpResponseRedirect(self.get_success_url())
            # Given that we bypassed AjaxCapableProcessFormViewMixin,
            # we'll have to call invoke it manually...
            res = _ajax_response(request, res, data=self._get_ajax_data_if())
        else:
            # No email address selected
            res = HttpResponseRedirect(self.success_url)
            res = _ajax_response(request, res, data=self._get_ajax_data_if())
        return res

    def _get_email_address(self, request):
        email = request.POST["email"]
        try:
            validate_email(email)
        except ValidationError:
            return None
        try:
            return EmailAddress.objects.get_for_user(user=request.user, email=email)
        except EmailAddress.DoesNotExist:
            pass

    def _action_send(self, request, *args, **kwargs):
        email_address = self._get_email_address(request)
        if email_address:
            send_email_confirmation(
                self.request, request.user, email=email_address.email
            )

    def _action_remove(self, request, *args, **kwargs):
        email_address = self._get_email_address(request)
        if email_address:
            if flows.manage_email.delete_email(request, email_address):
                return HttpResponseRedirect(self.get_success_url())

    def _action_primary(self, request, *args, **kwargs):
        email_address = self._get_email_address(request)
        if email_address:
            if flows.manage_email.mark_as_primary(request, email_address):
                return HttpResponseRedirect(self.get_success_url())

    def get_context_data(self, **kwargs):
        ret = super(EmailView, self).get_context_data(**kwargs)
        emails = list(
            EmailAddress.objects.filter(user=self.request.user).order_by("email")
        )
        ret.update(
            {
                "emailaddresses": emails,
                "emailaddress_radios": [
                    {
                        "id": f"email_radio_{i}",
                        "checked": email.primary or len(emails) == 1,
                        "emailaddress": email,
                    }
                    for i, email in enumerate(emails)
                ],
                "add_email_form": ret.get("form"),
                "can_add_email": EmailAddress.objects.can_add_email(self.request.user),
            }
        )
        if app_settings.CHANGE_EMAIL:
            ret.update(
                {
                    "new_emailaddress": EmailAddress.objects.get_new(self.request.user),
                    "current_emailaddress": EmailAddress.objects.get_verified(
                        self.request.user
                    ),
                }
            )
        return ret

    def get_ajax_data(self):
        data = []
        for emailaddress in self.request.user.emailaddress_set.all().order_by("pk"):
            data.append(
                {
                    "id": emailaddress.pk,
                    "email": emailaddress.email,
                    "verified": emailaddress.verified,
                    "primary": emailaddress.primary,
                }
            )
        return data


class ConfirmLoginCodeView(RedirectAuthenticatedUserMixin, NextRedirectMixin, FormView):
    form_class = ConfirmLoginCodeForm
    template_name = "account/confirm_login_code." + app_settings.TEMPLATE_EXTENSION

    @method_decorator(never_cache)
    def dispatch(self, request, *args, **kwargs):
        self.user, self.pending_login = flows.login_by_code.get_pending_login(
            request, peek=True
        )
        # if not self.pending_login:
        #     return HttpResponseRedirect(reverse("account_request_login_code"))
        return super().dispatch(request, *args, **kwargs)

    def get_form_class(self):
        return get_form_class(app_settings.FORMS, "confirm_login_code", self.form_class)

    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs["code"] = self.pending_login.get("code", "")
        return kwargs

    def form_valid(self, form):
        login_code = form.cleaned_data['code']
        user = self.user

        if login_code == self.pending_login.get("code") and not self.pending_login.get("is_expired"):
            perform_login(self.request, user, email_verification=settings.ACCOUNT_EMAIL_VERIFICATION)
            return redirect(self.get_success_url())
        else:
            form.add_error('code', 'Invalid code')
            return self.form_invalid(form)
    
    def form_invalid(self, form):
        attempts_left = flows.login_by_code.record_invalid_attempt(
            self.request, self.pending_login
        )
        if attempts_left:
            return super().form_invalid(form)
        adapter = get_adapter(self.request)
        adapter.add_message(
            self.request,
            messages.ERROR,
            message=adapter.error_messages["too_many_login_attempts"],
        )
        return HttpResponseRedirect(reverse("account_request_login_code"))

    def get_context_data(self, **kwargs):
        ret = super().get_context_data(**kwargs)
        site = get_current_site(self.request)
        ret.update(
            {
                "site": site,
                "email": self.pending_login["email"],
            }
        )
        return ret

    def get_success_url(self):
        next_url = self.request.session.get('next', '')
        if next_url:
            del self.request.session['next']
            return next_url
        return get_login_redirect_url(self.request)


def verification_sent(request):
    contact_url = reverse('portfolio:top') + '#contact'
    context = {
        'contact_url': contact_url
    }
    return render(request, 'account/verification_sent.html', context)

def password_reset_done(request):
    contact_url = reverse('portfolio:top') + '#contact'
    context = {
        'contact_url': contact_url
    }
    return render(request, 'account/password_reset_done.html', context)

@login_required
def login_by_code_settings(request):
    if request.method == 'POST':
        form = LoginByCodeSettingsForm(request.POST, instance=request.user)
        if form.is_valid():
            form.save()
            messages.success(request, 'Settings updated successfully.')
            return redirect('/')
        else:
            messages.error(request, 'There was an error updating your settings.')
    else:
        form = LoginByCodeSettingsForm(instance=request.user)
    return render(request, 'account/login_by_code_settings.html', {'form': form})
