# TODO: urldecode

request = require 'request'

class PayPal
  proxy_host: '127.0.0.1'
  proxy_port: '808'
  bnCode: 'PP-ECWizard'
  useProxy: false
  version: '64'

  constructor: (@apiUserName, @apiPassword, @apiSignature, @sandboxFlag = true) ->
    if @sandboxFlag
      @apiEndpoint = 'https://api-3t.sandbox.paypal.com/nvp'
      @paypalUrl = 'https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token='
    else
      @apiEndpoint = 'https://api-3t.paypal.com/nvp'
      @paypalUrl = 'https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token='
    @

  ###
  # params: session, paymentAmt [, currencyCodeType, paymentType], returnUrl, cancelUrl, callback
  ####
  shortExpressCheckout: (session, paymentAmt, args...) ->
    cb = args.pop()
    cancelUrl = args.pop()
    returnUrl = args.pop()
    currencyCodeType = 'USD'
    paymentType = 'SALE'
    currencyCodeType = args.shift() if args.length
    paymentType = args.shift() if args.length

    hash = 
      paymentrequest_0_amt: paymentAmt
      paymentrequest_0_paymentaction: paymentType
      returnurl: returnUrl
      cancelurl: cancelUrl
      paymentrequest_0_currencycode: currencyCodeType

    @hashCall 'SetExpressCheckout', nvp, (err, res) ->
      cb err, res if err?
      ack = res.ack?.toLowerCase()
      if ack is 'success' or ack is 'successwithwarning'
        token = urldecode res.token
        session.token = token
      cb err, res
    @

  hashCall: (methodName, hash) ->
    hash.method = methodName
    hash.version = @version
    hash.pwd = @apiPassword
    hash.user = @apiUserName
    hash.signature = @apiSignature
    hash.buttonsource = @bnCode

    parts = []
    for key, value of hash when hash.hasOwnProperty key
      parts = key.toUpperCase() + '=' + urlencode value


module.exports = exports = PayPal 
