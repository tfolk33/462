ruleset sensor_profile {
    meta {
      name "Sensor Profile"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab5
      >>

      use module io.picolabs.wrangler alias wrangler

      use module io.picolabs.subscription alias subs

      provides sensor_name, sensor_location, contact_number, threshold_temp
      shares sensor_name, sensor_location, contact_number, threshold_temp
    }

    global {
        sensor_name = function (){
            ent:sensor_name.defaultsTo("Sensor")
        }

        sensor_location = function (){
            ent:sensor_location.defaultsTo("Main Level")
        }

        contact_number = function (){
            ent:contact_number.defaultsTo("+14438129301") 
        }

        sensor_eci = function (){
            ent:sensor_eci.defaultsTo() 
        }

        threshold_temp = function (){
            ent:threshold_temp.defaultsTo(60) 
        }
    }

    rule capture_initial_state {
        select when wrangler ruleset_installed
          where event:attr("rids") >< meta:rid
        if ent:sensor_eci.isnull() then
          wrangler:createChannel() setting(channel)
        fired {
          ent:name := event:attr("name")
          ent:wellKnown_Rx := event:attr("wellKnown_Rx").klog()
          ent:sensor_eci := channel{"id"}
          raise sensor event "new_subscription_request"
        }
    }

    rule update_threshold {
      select when sensor update_threshold
      pre {
        new_temp = event:attrs{"NewThreshold"}
      }
      fired {
        ent:threshold_temp := new_temp
      }
  }

    rule make_a_subscription {
        select when sensor new_subscription_request
        event:send({"eci":ent:wellKnown_Rx,
          "domain":"wrangler", "name":"subscription",
          "attrs": {
            "wellKnown_Tx":subs:wellKnown_Rx(){"id"},
            "Rx_role":"subscription", "Tx_role":"sensor",
            "name":ent:sensor_name+"-subscription", "channel_type":"subscription"
          }
        })
    }

    rule auto_accept {
        select when wrangler inbound_pending_subscription_added
        pre {
          my_role = event:attr("Rx_role").klog()
          their_role = event:attr("Tx_role").klog()
        }
        if ((my_role=="sensor" && their_role=="subscription") || (my_role == "node" && their_role == "node")) then noop()
        fired {
          raise wrangler event "pending_subscription_approval"
            attributes event:attrs
          ent:subscriptionTx := event:attr("Tx")
        } else {
          raise wrangler event "inbound_rejection"
            attributes event:attrs
        }
    }

    rule collect_temperatures {
        select when sensor profile_updated 

        pre {
            sns_name = event:attrs{"SensorName"}.klog()
            sns_location = event:attrs{"SensorLocation"}.klog()
            cntc_num = event:attrs{"ContactNumber"}.klog()
            thresh_temp = event:attrs{"ThresholdTemp"}.klog()
        }
        always {
            ent:sensor_name := sns_name
            ent:sensor_location := sns_location
            ent:contact_number := cntc_num
            ent:threshold_temp := thresh_temp
        }
        
    }
}
