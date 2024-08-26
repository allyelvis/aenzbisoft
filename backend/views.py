from rest_framework import generics
from .models import YourModel
from .serializers import YourModelSerializer

class YourModelListCreateView(generics.ListCreateAPIView):
    queryset = YourModel.objects.all()
    serializer_class = YourModelSerializer
