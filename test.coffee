fs = require 'fs'
Paypal = require './index'

try
  {username, password, sig, success, cancel} = JSON.parse fs.readFileSync 'paypal_test_cred.json'
catch ex
  console.error 'Create or check the format of paypal_test_cred.json'
  process.exit -1

paypal = new Paypal username, password, sig # this runs against the sandbox
paypal.debug = true

session = {}
paypal.shortExpressCheckout session, '9.45', success, cancel, (err, response) ->
  console.error err.stack or err if err
  console.log response
