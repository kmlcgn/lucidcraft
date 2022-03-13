
from django.urls import path
from api.views import MergeNFTsView, MergeUploadNFTsView
app_name = 'api'

urlpatterns = [
    path(r'merge/', MergeNFTsView.as_view(), name='user_get'),
    path(r'merge_upload/', MergeUploadNFTsView.as_view(), name='user_create'),
]