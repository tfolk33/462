ruleset wovyn_base {
    meta {
      name "Wovyn Base"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab3
      >>

      use module io.picolabs.subscription alias subs

      use module sensor_profile alias sensor
    }

    global {
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
            temperature_threshold = sensor:threshold_temp()
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
            eci = subs:established()[0]{"Tx"}.klog()
            temperature = event:attrs{"temperature"}
            timestamp = event:attrs{"timestamp"}
            temperature_threshold = sensor:threshold_temp()
            msg = "Temperature " + temperature + " exceeded limit of " + temperature_threshold + " at " + timestamp
        }
        event:send({"eci":eci,
          "domain":"manager", "name":"threshold_violation",
          "attrs": {
            "msg":msg
          }
        })
    }
}
