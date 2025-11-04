from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

def home_view(request):
    return HttpResponse("""
    <html>
        <head><title>Django App</title></head>
        <body>
            <h1>Hello from Django!</h1>
            <p>This Django application is running successfully.</p>
            <p><a href="/admin/">Admin Panel</a></p>
        </body>
    </html>
    """)

urlpatterns = [
    path('', home_view),
    path('admin/', admin.site.urls),
]
