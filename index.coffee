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
  # params: paymentAmt [, currencyCodeType, paymentType], returnUrl, cancelUrl, callback
  ####
  shortExpressCheckout: (paymentAmt, args...) ->
    cb = args.pop()
    cancelUrl = args.pop()
    returnUrl = args.pop()
    noshipping = '0'
    currencyCodeType = 'USD'
    paymentType = 'Sale'
    noshipping = args.shift() if args.length
    currencyCodeType = args.shift() if args.length
    paymentType = args.shift() if args.length

    hash = 
      paymentrequest: [{
        amt: paymentAmt
        paymentaction: paymentType
        currencycode: currencyCodeType
      }]
      returnurl: returnUrl
      cancelurl: cancelUrl

    @hashCall 'SetExpressCheckout', hash, (err, res) ->
      return cb err, res if err?
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
    for key, value of nvp when nvp.hasOwnProperty key
      if typeof value is 'object'
        for tmp, index in value
          @log index
          if typeof tmp is 'object'
            for k,v of tmp when tmp.hasOwnProperty k
              @log k, v
              hash["#{key}_#{index}_#{k}"] = v
          else
            hash["l_#{key}#{index}"] = tmp
      else
        hash[key] = value 
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
      SIMPLE_ARRAY = /^l_(.+)([0-9]+)$/
      OBJECT_ARRAY = /^(.+)_([0-9]+)_(.+)$/
      return callback err, null if err
      parts = body.split '&'
      obj = {}
      for part in parts
        segment = part.split '='
        key = segment[0].toLowerCase()
        value = segment[1] if segment.length > 1
        value = urldecode value
        if SIMPLE_ARRAY.test key
          console.log 'deal with simple arrays', key
          keyparts = SIMPLE_ARRAY.exec key
          a = obj[keyparts[1]]
          a = [] unless a?
          a[+keyparts[2]] = value
          obj[keyparts[1]] = a
        else if OBJECT_ARRAY.test key
          console.log 'Object Array', key
        else
          obj[key] = value
      obj.ack = obj.ack?.toLowerCase()
      if obj.ack is 'failure'
        err = obj.longmessage[0]
      callback err, obj


module.exports = exports = PayPal 
