fs = require 'fs'
Paypal = require './index'

try
  {username, password, sig, success, cancel, amount, currency, paymentType} = JSON.parse fs.readFileSync 'paypal_test_cred.json'
catch ex
  console.error 'Create or check the format of paypal_test_cred.json'
  process.exit -1

paypal = new Paypal username, password, sig # this runs against the sandbox
paypal.debug = true
amount or= '9.45'
paypal.defaultCurrency = currency if currency?
paypal.defaultPaymentType = paymentType if paymentType?


onError = (err) ->
  console.error err.stack or err
  process.exit -1

# Billing...
billing = (cb) ->
  console.log 'BILLING'
  paypal.shortExpressCheckout amount, success, cancel, (err, response) ->
    onError err if err
    console.log response
    unless err
      console.log 'should redirect to ' + paypal.paypalUrl + response.token
      cb(response) if cb?

# Order Review
orderReview = (token, cb) ->
  console.log 'ORDER REVIEW'
  paypal.getShippingDetails token, (err, details) ->
    onError err if err
    console.log details
    unless err
      cb(details) if cb?

# Order Confirm
orderConfirm = (session, cb) ->
  console.log 'ORDER CONFIRM'
  paypal.confirmPayment session.token, session.payerid, amount, (err, ticket) ->
    onError err if err
    console.log ticker
    unless err
      cb(ticket) if cb?


# Run tests
billing (response) ->
  orderReview response.token
