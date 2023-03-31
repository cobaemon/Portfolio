from django import forms


class ContactForm(forms.Form):
    full_name = forms.CharField(
        label='Full Name', 
        max_length=100,
        widget=forms.TextInput(attrs={
            'name': 'full_name',
            'class': 'form-control',
            'placeholder': 'Enter your name...'
        })
    )
    email = forms.EmailField(
        label='Email Address',
        widget=forms.TextInput(attrs={
            'name': 'email',
            'class': 'form-control',
            'placeholder': 'name@example.com',
            'data-sb-validations': 'required,email'
        })
    )
    phone_number = forms.CharField(
        label='Phone Number',
        max_length=20,
        widget=forms.TextInput(attrs={
            'name': 'phone_number',
            'class': 'form-control',
            'placeholder': '(123) 456-7890'
        })
    )
    message = forms.CharField(
        label='Message',
        widget=forms.Textarea(attrs={
            'name': 'message',
            'class': 'form-control',
            'placeholder': 'Enter your message here...'
        })
    )

    def clean_phone_number(self):
        phone_number = self.cleaned_data.get('phone_number')
        if not phone_number.isdigit():
            raise forms.ValidationError('Phone number should only contain digits')
        return phone_number
