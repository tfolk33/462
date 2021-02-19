ruleset sensor_profile {
    meta {
      name "Sensor Profile"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab5
      >>
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

        threshold_temp = function (){
            ent:threshold_temp.defaultsTo(60) 
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
