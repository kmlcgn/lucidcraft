const { Requester, Validator } = require('@chainlink/external-adapter')
//const axios = require('axios');

// Define custom error scenarios for the API.
// Return true for the adapter to retry.
const customError = (data) => {
  if (data.Response === 'Error') return true
  return false
}

// Define custom parameters to be used by the adapter.
// Extra parameters can be stated in the extra object,
// with a Boolean value indicating whether or not they
// should be required.

const customParams = {
  tshirt_uri: ['tshirt_uri'],
  other_nft_uri: ['other_nft_uri']

    //nftContractAddress: ['nftContractAddress'],
    //nftId: ['nftId'],
    //tshirtContractAddress: ['tshirtContractAddress'],
    //tshirtId: ['tshirtId'],
}

const createRequest = (input, callback) => {

  // The Validator helps you validate the Chainlink request data
  const validator = new Validator(callback, input, customParams)
  const jobRunID = validator.validated.id

  const tshirt_uri = validator.validated.data.tshirt_uri
  const other_nft_uri = validator.validated.data.other_nft_uri

  //const nftContractAddress = validator.validated.data.nftContractAddress
  //const nftId = validator.validated.data.nftId
  //const tshirtContractAddress = validator.validated.data.tshirtContractAddress
  //const tshirtId = validator.validated.data.tshirtId

  //const url = "https://localhost:8000/api/"
  //https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740
  //https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740

  const url = `http://127.0.0.1:8000/api/merge_upload/?tshirt_uri=${tshirt_uri}&other_nft_uri=${other_nft_uri}`

  const params = {
    tshirt_uri,
    other_nft_uri
    //nftContractAddress,
    //nftId,
    //tshirtContractAddress,
    //tshirtId
  }

  const config = {
    url,
    params,
    //method: "GET",
    //headers: {
    //  "Client-ID": process.env.API_KEY,
    //  'Authorization': 'Bearer ' + accessToken
    //}      
  }

 /*
  var getTokenConfig = {
    url: 'https://localhost:8000/token',
    method: 'POST',
    params: {
      client_id: process.env.API_KEY,
      client_secret: process.env.API_SECRET,
      grant_type: 'client_credentials'
    }
  }
  

  var accessToken = 'failed to get token';
  const tokenResponse2 = axios.request(getTokenConfig).then((tokenResponse) => {

    accessToken = tokenResponse.data.access_token

    
  */
    
  
    
  
    Requester.request(config, customError)
    .then(response => {

    // Setting our data in a specific variable so that our Chainlink node
    // knows where to look for what we want to send back to the blockchain
      response.data.result = response.data.newURI;
  
      response.status = 200;
      console.log(response.data);
      callback(response.status, Requester.success(jobRunID, response));
    })

    .catch(error => {
      callback(500, Requester.errored(jobRunID, error))
    })


  }

// This is a wrapper to allow the function to work with
// GCP Functions
exports.gcpservice = (req, res) => {
  createRequest(req.body, (statusCode, data) => {
    res.status(statusCode).send(data)
  })
}

// This is a wrapper to allow the function to work with
// AWS Lambda
exports.handler = (event, context, callback) => {
  createRequest(event, (statusCode, data) => {
    callback(null, data)
  })
}

// This is a wrapper to allow the function to work with
// newer AWS Lambda implementations
exports.handlerv2 = (event, context, callback) => {
  createRequest(JSON.parse(event.body), (statusCode, data) => {
    callback(null, {
      statusCode: statusCode,
      body: JSON.stringify(data),
      isBase64Encoded: false
    })
  })
}

// This allows the function to be exported for testing
// or for running in express
module.exports.createRequest = createRequest
