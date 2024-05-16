from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.utils.translation import activate
from django.conf import settings
from django.contrib import messages
from .forms import ContactForm, LanguageForm

def top_view(request):
    if request.method == 'POST':
        if 'contact_form' in request.POST:
            contact_form = ContactForm(request.POST)
            language_form = LanguageForm()
            if contact_form.is_valid():
                contact_form.send_email()
                messages.success(request, "Contact form submitted successfully.")
                return redirect('portfolio:top')
        elif 'language_form' in request.POST:
            contact_form = ContactForm()
            language_form = LanguageForm(request.POST)
            if language_form.is_valid():
                lang_code = language_form.cleaned_data['language']
                activate(lang_code)
                response = redirect(request.POST.get('next', '/'))
                response.set_cookie(settings.LANGUAGE_COOKIE_NAME, lang_code)
                return response
    else:
        contact_form = ContactForm()
        language_form = LanguageForm()

    return render(request, 'index.html', {
        'contact_form': contact_form,
        'language_form': language_form,
    })
