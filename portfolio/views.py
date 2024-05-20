from django.views.generic import FormView
from django.http import HttpResponse
from .forms import ContactForm
from django.views.decorators.csrf import csrf_protect
from django.shortcuts import redirect
from django.utils.translation import activate
from django.conf import settings


class Top(FormView):
    template_name = 'index.html'
    form_class = ContactForm

    def form_valid(self, form):
        form.send_email()
        return HttpResponse("Form submission successful")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['form'] = self.form_class()
        return context

@csrf_protect
def set_language(request):
    if request.method == "POST":
        language = request.POST.get('language')
        if language:
            activate(language)
            request.session[settings.LANGUAGE_SESSION_KEY] = language
    return redirect(request.POST.get('next', '/'))
