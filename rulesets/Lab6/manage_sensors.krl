ruleset manage_sensor {
    meta {
      name "Manage Sensor"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab6
      >>

      use module io.picolabs.wrangler alias wrangler

      use module io.picolabs.subscription alias subs

      use module twilio alias t
        with
          SID = meta:rulesetConfig{"SID"}
          authToken = meta:rulesetConfig{"auth"}

      provides sensors, query_temps, query_temp, query_sensor_profile, parent
      shares sensors, query_temps, query_temp, query_sensor_profile, parent
    }

    global {
        sensors = function (){
            ent:sensors.defaultsTo({})
        }

        parent = function (){
            ent:parent_wk.defaultsTo(subs:wellKnown_Rx(){"id"})
        }

        default_threshold = 60

        query_temps = function(){
            subs = subs:established().klog()
            result = subs.map(function(res){ctx:query(res{"Tx"}, "temperature_store", "temperatures")})
            result
        }

        query_temp = function(eci){
            ctx:query(eci, "temperature_store", "temperatures")
        }

        query_sensor_profile = function(eci){
            sensor_name = ctx:query(eci, "sensor_profile", "sensor_name")
            sensor_location = ctx:query(eci, "sensor_profile", "sensor_location")
            contact_number = ctx:query(eci, "sensor_profile", "contact_number")
            threshold_temperature = ctx:query(eci, "sensor_profile", "threshold_temp")
            ret = {"eci":eci, "Sensor Name":sensor_name, "Sensor Location":sensor_location, 
                    "Contact Number":contact_number, "Threshold Temperature":threshold_temperature}
            ret 
        }
    }

    rule threshold_notification {
        select when manager threshold_violation 

        pre {
            msg = event:attrs{"msg"}
        }
        t:sendMessage(msg) setting(response)
        fired {
            ent:lastResponse := response.klog()
        }
    }

    rule make_a_subscription {
        select when manager new_subscription_request
        pre {
            sub_wellKnown = event:attrs{"sub_wellKnown"}
        }
        event:send({"eci":subs:wellKnown_Rx(){"id"},
          "domain":"wrangler", "name":"subscription",
          "attrs": {
            "wellKnown_Tx":sub_wellKnown,
            "Rx_role":"subscription", "Tx_role":"sensor",
            "name":"subscription", "channel_type":"subscription"
          }
        })
    }

    rule manage_sensors {
        select when sensor new_sensor 

        pre {
            sensor_name = event:attrs{"SensorName"}
            body = { "name": sensor_name }.klog()
            // Check existing names of sensors
            exists = ent:sensors.filter(function(v,k){v==sensor_name})
        }
        if exists == {} then noop()
        always {
            raise wrangler event "new_child_request"
            attributes body
        }
    }

    rule install_wovyn {
        select when manager install_wovyn 

        pre {
            eci = event:attrs{"eci"}
            name  = event:attrs{"name"}.klog()

        }
        if name then
        event:send(
            { "eci": eci,
              "eid": "install-wovyn",
              "domain": "wrangler", "type": "install_ruleset_request",
              "attrs": {
                  "absoluteURL": "file:///Users/TFolk/repos/462/rulesets/Lab3/wovyn_base.krl",
                  "rid": "wovyn_base",
              }
            }
        )
        fired
        {
            raise manager event "update_profile" 
            attributes { "name":name, "eci":eci}
        }
    }

    rule install_sensor_profile {
        select when wrangler new_child_created 

        pre {
            eci = event:attrs{"eci"}
            name  = event:attrs{"name"}
            wk = subs:wellKnown_Rx(){"id"}
        }
        if name then
        event:send(
            { "eci": eci,
              "eid": "install-sensor-profile",
              "domain": "wrangler", "type": "install_ruleset_request",
              "attrs": {
                  "absoluteURL": "file:///Users/TFolk/repos/462/rulesets/Lab4/sensor_profiles.krl",
                  "rid": "sensor_profile",
                  "wellKnown_Rx": wk
              }
            }
        )
        fired
        {
            raise manager event "install_wovyn" attributes event:attrs
        }
    }

    rule install_temperature_store {
        select when wrangler new_child_created 

        pre {
            eci = event:attrs{"eci"}
            name  = event:attrs{"name"}

        }
        if name then
        event:send(
            { "eci": eci,
              "eid": "install-temperature-store",
              "domain": "wrangler", "type": "install_ruleset_request",
              "attrs": {
                  "absoluteURL": "file:///Users/TFolk/repos/462/rulesets/Lab4/temperature_store.krl",
                  "rid": "temperature_store",
              }
            }
        )
    }

    rule install_emitter {
        select when wrangler new_child_created 

        pre {
            eci = event:attrs{"eci"}
            name  = event:attrs{"name"}

        }
        if name then
        event:send(
            { "eci": eci,
              "eid": "install-emitter",
              "domain": "wrangler", "type": "install_ruleset_request",
              "attrs": {
                  "absoluteURL": "file:///Users/TFolk/repos/462/rulesets/Lab6/io.picolabs.wovyn.emitter.krl",
                  "rid": "io.picolabs.wovyn.emitter",
              }
            }
        )
    }

    rule update_sensors_addition {
        select when wrangler new_child_created 

        pre {
            eci = event:attrs{"eci"}.klog()
            name  = event:attrs{"name"}.klog()
        }
        always {
            ent:sensors{eci} := name
        }
    }

    rule update_sensors_deletion {
        select when wrangler child_deleted

        pre {
            eci = event:attrs{"eci"}
        }
        always {
            ent:sensors := ent:sensors.delete(eci)
        }
    }

    rule reset_sensors {
        select when manager reset_sensors

        always {
            ent:sensors := {}
        }
    }

    rule delete_sensor {
        select when sensor unneeded_sensor 

        pre {
            name = event:attrs{"name"}
            eci = ent:sensors.filter(function(v,k){v==name}).keys()[0].klog()
            body = { "eci": eci }
        }
        always
        {
            raise wrangler event "child_deletion_request"
            attributes body
        }
    }

    rule update_profile {
        select when manager update_profile 

        pre {
            name = event:attrs{"name"}
            eci = event:attrs{"eci"}
            body = {"SensorName":name, "ThresholdTemp":default_threshold}
        }
        ctx:event(eci, "sensor", "profile_updated", body)
        fired
        {
            raise manager event "get_parent_wellKnown" attributes {}
        }
    }
}
