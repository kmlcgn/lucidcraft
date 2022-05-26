from django.urls import path
from api.views import MergeNFTsView, MergeUploadNFTsView, GetUserNfts
app_name = 'api'

urlpatterns = [
    path(r'merge/', MergeNFTsView.as_view(), name='user_get'),
    path(r'merge_upload/', MergeUploadNFTsView.as_view(), name='user_create'),
    path(r'get_user_nfts/', GetUserNfts.as_view(), name="get_user_nfts")
]