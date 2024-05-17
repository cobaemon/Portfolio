from django import forms
from django.core.mail import EmailMessage
from django.utils.translation import gettext_lazy as _
from django.conf import settings


class ContactForm(forms.Form):
    full_name = forms.CharField(
        label='Full Name', 
        max_length=100,
        widget=forms.TextInput(attrs={
            'name': 'full_name',
            'class': 'form-control',
            'placeholder': _('Enter your name...')
        }),
        error_messages={
            'required': _('This field is required.'),
            'max_length': _('Name cannot exceed 100 characters.')
        }
    )
    email = forms.EmailField(
        label='Email Address',
        widget=forms.TextInput(attrs={
            'name': 'email',
            'class': 'form-control',
            'placeholder': 'name@example.com',
            'data-sb-validations': 'required,email'
        }),
        error_messages={
            'required': _('This field is required.'),
            'invalid': _('Enter a valid email address.')
        }
    )
    phone_number = forms.CharField(
        label='Phone Number',
        max_length=20,
        widget=forms.TextInput(attrs={
            'name': 'phone_number',
            'class': 'form-control',
            'placeholder': '(123) 456-7890'
        }),
        error_messages={
            'required': _('This field is required.'),
            'max_length': _('Phone Number cannot exceed 20 characters.')
        }
    )
    message = forms.CharField(
        label='Message',
        widget=forms.Textarea(attrs={
            'name': 'message',
            'class': 'form-control',
            'placeholder': _('Enter your message here...')
        }),
        error_messages={
            'required': _('This field is required.')
        }
    )

    def clean_phone_number(self):
        phone_number = self.cleaned_data.get('phone_number')
        if not phone_number.isdigit():
            raise forms.ValidationError(_('Phone number should only contain digits'))
        return phone_number
    
    def send_email(self):
        full_name = self.cleaned_data['full_name']
        email = self.cleaned_data['email']
        phone_number = self.cleaned_data['phone_number']
        message = self.cleaned_data['message']

        subject = f'Contact form submission from {full_name}'
        body = f'Full Name: {full_name}\nEmail: {email}\nPhone Number: {phone_number}\n\nMessage:\n{message}'

        email = EmailMessage(
            subject,
            body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[settings.DEFAULT_TO_EMAIL]
        )
        try:
            email.send()
        except Exception as e:
            # エラーハンドリング
            raise forms.ValidationError(_('An error occurred while sending the email: {error}').format(error=str(e)))


class LanguageForm(forms.Form):
    language = forms.ChoiceField(choices=settings.LANGUAGES, widget=forms.Select)
