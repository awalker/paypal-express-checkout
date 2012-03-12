request = require 'request'

urlencode = encodeURIComponent
urldecode = decodeURIComponent
SIMPLE_ARRAY = /^l_(.+)([0-9]+)$/
OBJECT_ARRAY = /^(.+)_([0-9]+)_(.+)$/

class PayPal
  proxy_host: '127.0.0.1'
  proxy_port: '808'
  bnCode: 'PP-ECWizard'
  useProxy: false
  version: '64'
  debug: false
  defaultCurrency: 'USD'
  defaultPaymentType: 'Sale'

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

  getPayPalUrl: (token) ->
    @paypalUrl + urlencode token

  ###
  # params: paymentAmt [, currencyCodeType, paymentType], returnUrl, cancelUrl, callback
  ####
  shortExpressCheckout: (paymentAmt, args...) ->
    cb = args.pop()
    cancelUrl = args.pop()
    returnUrl = args.pop()
    noshipping = '0'
    currencyCodeType = @defaultCurrency
    paymentType = @defaultPaymentType
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

  expressCheckout: (amt, returnUrl, cancelUrl, cb) ->
    if typeof amt is 'object'
      paymentRequest = obj
    else
      paymentRequest = 
        amt: amt
        paymentaction: @defaultPaymentType
        currencycode: @defaultCurrency
        noshipping: '1'
    hash =
      paymentrequest: [paymentRequest]
      returnurl: returnUrl
      cancelurl: cancelUrl
    @hashCall 'SetExpressCheckout', hash, cb
    @

  markExpressCheckout: (amt, currencyCode, paymentType, returnUrl, cancelUrl, args..., cb) ->
    pr = 
      amt: amt
      currencycode: currencyCode
      paymentType: paymentType
      shipToName: args.shift()
      shipToStreet: args.shift()
    pr.shipToPhoneNum = args.pop()
    pr.shipToCountryCode = args.pop()
    pr.shipToState = args.pop()
    pr.shipToZip = args.pop()
    pr.shipToCity = args.pop()
    pr.shipToStreet2 = args.shift() if args.length
    hash =
      paymentRequest: [pr]
      returnUrl: returnUrl
      cancelUrl: cancelUrl
      addrOverride: '1'

    @hashCall 'SetExpressCheckout', hash, cb

  directPayment: (amt, args..., cb) ->
    hash =
      amt: amt
      creditcardtype: args.shift()
      acct: args.shift()
      expdate: args.shift()
      cvv2: args.shift()
      firstname: args.shift()
      lastname: args.shift()
      street: args.shift()
      city: args.shift()
      state: args.shift()
      countrycode: args.shift()
    
    # Optional(?)
    ipAddress = args.pop() if args.length
    hash.ipAddress = ipAddress if ipAddress?
    @hashCall 'DoDirectPayment', hash, cb

  getShippingDetails: (token, cb) ->
    hash =
      token: token
    @hashCall 'GetExpressCheckoutDetails', hash, cb

  confirmPayment: (token, payerId, amt, args..., cb) ->
    currencyCode = args.pop() if arg.length
    paymentType = args.pop() if args.length
    serverName = args.pop() if args.length
    paymentType or= @defaultPaymentType
    currencyCode or= @defaultCurrency
    serverName or= @serverName if @serverName?

    pr =
      amt: amt
      paymentAction: paymentType
      currencyCode: currencyCode
    pr.ipAddress = serverName if serverName?

    hash =
      token: token
      payerId: payerId
      paymentRequest: [pr]
    @hashCall 'DoExpressCheckoutPayment', hash, cb

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
      return callback err, null if err
      parts = body.split '&'
      obj = {}
      for part in parts
        segment = part.split '='
        key = segment[0].toLowerCase()
        value = segment[1] if segment.length > 1
        value = urldecode value
        if SIMPLE_ARRAY.test key
          keyparts = SIMPLE_ARRAY.exec key
          a = obj[keyparts[1]]
          a = [] unless a?
          a[+keyparts[2]] = value
          obj[keyparts[1]] = a
        else if OBJECT_ARRAY.test key
          keyparts = OBJECT_ARRAY.exec key
          a = obj[keyparts[1]]
          a = [] unless a?
          index = +keyparts[2]
          if index < a.length
            o = a[index]
          else
            o = {}
          o[keyparts[3]] = value
          a[index] = o
          obj[keyparts[1]] = a
        else
          obj[key] = value
      obj.ack = obj.ack?.toLowerCase()
      if obj.ack is 'failure'
        err = obj.longmessage[0]
      callback err, obj
    @


module.exports = exports = PayPal 
