ruleset twilio_app {
    meta {
      use module twilio alias t
        with
          SID = meta:rulesetConfig{"SID"}
          authToken = meta:rulesetConfig{"auth"}

      shares getMessages
    }
    global {
        getMessages = function(to, from, limit) {
            t:getMessages(to, from, limit)
        }

    }
    rule send_message {
        select when message send
        pre {
            to = event:attrs{"To"}
            fromVal = event:attrs{"From"}
            message = event:attrs{"Message"}
        }
        t:sendMessage(to.klog("To:"), fromVal.klog("From:"), message.klog("Message:")) setting(response)
        
        fired {
            ent:lastResponse := response
            ent:lastTimestamp := time:now()
            raise message event "Message Sent" attributes event:attrs
        }
    }
}
