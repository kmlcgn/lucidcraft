import environ
from django.shortcuts import render
from rest_framework.renderers import JSONRenderer
from rest_framework.views import APIView
from rest_framework.response import Response
from api.renderers import JPEGRenderer, PNGRenderer
from django.http import FileResponse, HttpResponse, JsonResponse

from PIL import Image
from io import BytesIO
from wsgiref.util import FileWrapper

import requests
import logging


class MergeNFTsView(APIView):
    """
    Class for user info.
    """
    permission_classes = []
    authentication_classes = []
    renderer_classes = [JPEGRenderer, PNGRenderer]

    def get(self, request, **kwargs):
        """
        Get user details.
        :param request: request
        :return: image response
        """

        #https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740
        print(request.query_params["tshirt_uri"])
        response = requests.get(request.query_params["tshirt_uri"])
        tshirt_json = response.json()
        print(tshirt_json)

        tshirt_img_url = tshirt_json["image"]
        tshirt_img = Image.open(BytesIO(requests.get(tshirt_img_url).content))


        response2 = requests.get(request.query_params["other_nft_uri"])
        other_nft_json = response2.json()
        print(other_nft_json)
        other_nft_img_url = other_nft_json["image"]
        other_nft_img = BytesIO(requests.get(tshirt_img_url).content)

        """
        Two images: tshirt_img, other_nft_img
        Merge them and create a new image, return it
        """

        return Response(FileWrapper(other_nft_img))


class MergeUploadNFTsView(APIView):
    """
    Class for user info.
    """
    permission_classes = []
    authentication_classes = []
    renderer_classes = [JSONRenderer, JPEGRenderer, PNGRenderer]

    def get(self, request, **kwargs):
        """
        4 inputs:
        tshirt_id, tshirt_address, nft_id, nft_address
        """
        # https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740
        # https://api.opensea.io/api/v1/asset/{asset_contract_address}/{token_id}/



        # Get Tshirt data & image
        ## try-except for multiple APIs

        completed = False

        # Alchemy API

        try:
            tshirt_id = request.query_params["tshirt_id"]
            tshirt_address = request.query_params["tshirt_address"]
            response = requests.get(f"https://eth-mainnet.alchemyapi.io/v2/demo/getNFTMetadata?contractAddress={tshirt_address}&tokenId={tshirt_id}&tokenType=erc721")
            tshirt_json = response.json()

            tshirt_metadata = tshirt_json["metadata"]
            tshirt_img_url = tshirt_json["media"][0]["gateway"]
            tshirt_img = Image.open(BytesIO(requests.get(tshirt_img_url).content))

            # Get Other NFT data & image
            nft_id = request.query_params["nft_id"]
            nft_address = request.query_params["nft_address"]
            response2 = requests.get(f"https://eth-mainnet.alchemyapi.io/v2/demo/getNFTMetadata?contractAddress={nft_address}&tokenId={nft_id}&tokenType=erc721")
            nft_json = response2.json()

            nft_metadata = nft_json["metadata"]
            nft_img_url = nft_json["media"][0]["gateway"]
            nft_img = Image.open(BytesIO(requests.get(nft_img_url).content))

            # TODO
            # Merge images, create new tshirt
            # Create new metadata
            # Upload it to IPFS

            completed = True
        except:
            pass


        if not completed:

            # try other APIs
            pass
        """
        Two images: tshirt_img, other_nft_img
        Merge them and create a new image, upload it to ipfs, return the URI
        """

        #return Response(FileWrapper(other_nft_img))
        return Response({"uri": "https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740"})


class GetUserNfts(APIView):

    base_url = "https://deep-index.moralis.io/api/v2/"
    url_ending = "/nft"

    env = environ.Env()
    api_key = env("MORALIS_KEY")

    def get(self, request, **kwargs):

        all_results = []
        address = ""

        try:
            address = request.GET.get('address', '')


        except:
            JsonResponse({"msg": 'Address not provided'}, status=500)
        try:

            url = self.base_url + address + self.url_ending
            req = requests.get(url, headers={"X-API-Key": self.api_key })
            res = req.json()

            total = res['total']
            cursor = res["cursor"]
            results = res['result']
            all_results += results

            while results != []:
                req = requests.get(url , headers={"X-API-Key": self.api_key }, params={"cursor": cursor})
                res = req.json()

                cursor = res["cursor"]
                results = res['result']
                all_results += results


            return JsonResponse({"total": total , "results": all_results}, status=200)


        except Exception as e:
            return JsonResponse({"msg" : str(e)}, status=500)

