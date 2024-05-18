import os
import base64
from django.shortcuts import render
from django.views.generic import FormView
from django.http import HttpResponse
from .forms import ContactForm

class Top(FormView):
    template_name = 'index.html'
    form_class = ContactForm

    def form_valid(self, form):
        form.send_email()
        return HttpResponse("Form submission successful")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        nonce = base64.b64encode(os.urandom(16)).decode('utf-8')
        context['nonce'] = nonce
        context['form'] = self.form_class()
        return context
