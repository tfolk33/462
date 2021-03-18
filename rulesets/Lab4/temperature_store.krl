ruleset temperature_store {
    meta {
      name "Temperature Store"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab4
      >>

      use module io.picolabs.subscription alias subs

      provides temperatures, threshold_violations, inrange_temperatures
      shares temperatures, threshold_violations, inrange_temperatures
    }

    global {
        temperatures = function (){
            ent:temps
        }

        threshold_violations = function (){
            ent:violations
        }

        inrange_temperatures = function (){
            ent:temps.difference(ent:violations)    
        }
    }

    rule temperature_report {
        select when temp periodic_temperature_report

        pre {
            temperature = temperatures().reverse()[0].klog()
            return_eci = event:attrs{"rx"}.klog()
            sender_id = subs:established().filter(function(res){res{"Tx"}==return_eci})[0]{"Rx"}.klog()
            rcn = event:attrs{"report_correlation_number"}
        }
        event:send({"eci":return_eci,
          "domain":"manager", "name":"periodic_temperature_report_created",
          "attrs": {
            "report_correlation_number": rcn,
            "sender_id": sender_id,
            "temperature": temperature
          }
        })
        
    }

    rule collect_temperatures {
        select when wovyn new_temperature_reading 

        pre {
            temperature = event:attrs{"temperature"}[0]{"temperatureF"}
            timestamp = event:attrs{"timestamp"}
            collection = {"Temperature":temperature, "Timestamp":timestamp}
        }
        always {
            ent:temps := ent:temps.defaultsTo([]).append(collection)
        }
        
    }

    rule threshold_notification {
        select when wovyn threshold_violation 

        pre {
            temperature = event:attrs{"temperature"}
            timestamp = event:attrs{"timestamp"}
            collection = {"Temperature":temperature, "Timestamp":timestamp}
        }
        always {
            ent:violations := ent:violations.defaultsTo([]).append(collection)
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset 

        pre {
    
        }
        always {
            clear ent:temps
            clear ent:violations
        }
    }
}
