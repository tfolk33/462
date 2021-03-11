ruleset wovyn_base {
    meta {
      name "Wovyn Base"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab4
      >>

      use module twilio alias t
        with
          SID = meta:rulesetConfig{"SID"}
          authToken = meta:rulesetConfig{"auth"}

      use module sensor_profile alias sensor
    }

    global {
        temperature_threshold = sensor:sensor_name
        to_num = sensor:contact_number
        from_num = "+19014727182"
    }
  
    rule process_heartbeat {
        select when wovyn heartbeat

        if event:attrs{"genericThing"} then every {
          send_directive("say", {"something":"New Temperature Reading"}) 
        }
        fired {
            raise wovyn event "new_temperature_reading"
                attributes { "temperature":event:attrs{"genericThing"}{"data"}{"temperature"}, "timestamp":time:now() }
        }
    }

    rule find_high_temps {
        select when wovyn new_temperature_reading 

        pre {
            temperatureF = event:attrs{"temperature"}[0]{"temperatureF"}
            timestamp = event:attrs{"timestamp"}
        }
        if (temperatureF.klog("TEMP: ") > temperature_threshold) then every {
            send_directive("say", {"something":"New Threshold Violation!"}) 
        }
        fired {
            raise wovyn event "threshold_violation"
                attributes { "temperature":temperatureF, "timestamp":timestamp}
        }
    }

    rule threshold_notification {
        select when wovyn threshold_violation 

        pre {
            temperature = event:attrs{"temperature"}
            timestamp = event:attrs{"timestamp"}
            msg = "Temperature " + temperature + " exceeded limit of " + temperature_threshold + " at " + timestamp
        }
        t:sendMessage(to_num, from_num, msg) setting(response)
        
        fired {
            ent:lastResponse := response
            ent:lastTimestamp := time:now()
            raise message event "Message Sent" attributes event:attrs
        }
    }
}
