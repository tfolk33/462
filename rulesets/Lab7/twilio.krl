ruleset twilio {
  meta {
    name "Twilio SDK"
    author "Tanner Folkman"
    description <<
      An SDK for twilio
    >>

    configure using
      SID = ""
      authToken = ""

    provides sendMessage, getMessages
  }

  global {
    base_url = "https://api.twilio.com"
    notification_num = "+14438129301"
    from_num = "+19014727182"

    getMessages = function(to, sender, limit) {
      queryString = {"AuthToken":authToken}
      authVal = {"username":SID, "password":authToken}
      response = http:get(<<#{base_url}/2010-04-01/Accounts/#{SID}/Messages.json>>, qs=queryString, auth=authVal)
      
      messages = response{"content"}.decode(){"messages"}
      ToFilter = to.klog("To: ") => messages.filter(function(x){x{"to"} == to}) | messages
      FromFilter = sender.klog("From: ") => ToFilter.filter(function(x){x{"from"} == sender}) | ToFilter
      LimitFilter = limit.klog("Limit: ") => FromFilter.slice(limit - 1) | FromFilter

      LimitFilter
    }

    sendMessage = defaction(message) {
      body = {"To":notification_num, "From":from_num, "Body":message}
      authVal = {"username":SID, "password":authToken}
      http:post(<<#{base_url}/2010-04-01/Accounts/#{SID}/Messages.json>>, form=body, auth=authVal) setting(response)
      
      return response
    }
  }
}