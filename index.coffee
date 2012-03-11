urlencode = encodeURIComponent
urldecode = decodeURIComponent

request = require 'request'

class PayPal
  proxy_host: '127.0.0.1'
  proxy_port: '808'
  bnCode: 'PP-ECWizard'
  useProxy: false
  version: '64'
  debug: false

  constructor: (@apiUserName, @apiPassword, @apiSignature, @sandboxFlag = true) ->
    if @sandboxFlag
      @apiEndpoint = 'https://api-3t.sandbox.paypal.com/nvp'
      @paypalUrl = 'https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token='
    else
      @apiEndpoint = 'https://api-3t.paypal.com/nvp'
      @paypalUrl = 'https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token='
    @

  log: (args...) ->
    console.log.apply console, args if @debug

  ###
  # params: session, paymentAmt [, currencyCodeType, paymentType], returnUrl, cancelUrl, callback
  ####
  shortExpressCheckout: (session, paymentAmt, args...) ->
    cb = args.pop()
    cancelUrl = args.pop()
    returnUrl = args.pop()
    currencyCodeType = 'USD'
    paymentType = 'Sale'
    currencyCodeType = args.shift() if args.length
    paymentType = args.shift() if args.length

    hash = 
      paymentrequest_0_amt: paymentAmt
      paymentrequest_0_paymentaction: paymentType
      returnurl: returnUrl
      cancelurl: cancelUrl
      paymentrequest_0_currencycode: currencyCodeType

    @hashCall 'SetExpressCheckout', hash, (err, res) ->
      return cb err, res if err?
      ack = res.ack
      if ack is 'success' or ack is 'successwithwarning'
        token = urldecode res.token
        session.token = token
      cb err, res
    @

  hashCall: (methodName, nvp, callback) ->
    qs = require 'querystring'
    hash =
      method: methodName
      version: @version
      pwd: @apiPassword
      user: @apiUserName
      signature: @apiSignature
    hash[key] = value for key, value of nvp when nvp.hasOwnProperty key
    hash.buttonsource = @bnCode

    form = []
    for key, value of hash when hash.hasOwnProperty key
      form[key.toUpperCase()] = value

    @log form

    opts = 
      method: 'post'
      url: @apiEndpoint
      form: form
      sslStrict: false
    request opts, (err, r, body) ->
      return callback err, null if err
      parts = body.split '&'
      obj = {}
      for part in parts
        segment = part.split '='
        key = segment[0].toLowerCase()
        value = segment[1] if segment.length > 1
        obj[key] = urldecode value
      obj.ack = obj.ack?.toLowerCase()
      if obj.ack is 'failure'
        err = obj.l_longmessage0
      callback err, obj


module.exports = exports = PayPal 
