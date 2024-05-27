from django.shortcuts import render
from django.views.generic import FormView
from django.http import HttpResponse
from .forms import ContactForm
from csp.decorators import csp_update

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

    @csp_update(SCRIPT_SRC="'self' 'nonce-{nonce}'", STYLE_SRC="'self' 'nonce-{nonce}'")
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)
