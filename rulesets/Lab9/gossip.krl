ruleset gossip {
    meta {
      name "Gossip"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab10
      >>

      use module io.picolabs.subscription alias subs

      provides period, originID, sequence_number, message_tracker, seen_tracker, getMessages, all_peers_seen, peers_seen_tracker, violation_status, violations_seen_tracker, violations_tracker, sensors_in_violation, getViolationMessages
      shares period, originID, sequence_number, message_tracker, seen_tracker, getMessages, all_peers_seen, peers_seen_tracker, violation_status, violations_seen_tracker, violations_tracker, sensors_in_violation, getViolationMessages
      use module sensor_profile alias sensor
    }

    global {
        // STATE
        period = function (){
            ent:period
        }

        originID = function (){
            ent:originID
        }

        sequence_number = function (){
            ent:sequence_number
        }

        message_tracker = function (){
            ent:message_tracker
        }

        seen_tracker = function (){
            ent:seen_tracker
        }

        all_peers_seen = function (){
            peers = subs:established().filter(function(res){res{"Tx_role"}=="node"})
            peers.map(function(res){ctx:query(res{"Tx"}, "gossip", "seen_tracker")})
        }

        peers_seen_tracker = function(){
            ent:peers_seen_tracker
        }

        // Violation Status
        violation_status = function(){
            ent:violation_status
        }

        violations_seen_tracker = function (){
            ent:violations_seen_tracker
        }

        all_peers_seen_violations = function (){
            peers = subs:established().filter(function(res){res{"Tx_role"}=="node"})
            peers.map(function(res){ctx:query(res{"Tx"}, "gossip", "violations_seen_tracker")})
        }

        violations_tracker = function (){
            ent:violations_tracker
        }

        sensors_in_violation = function (){
            violation_tracker = violations_tracker().klog("all")
            in_violation = violation_tracker.map(function(v,k){v.reduce(function(a,b){a + b})}).values().klog("value")
            in_violation.reduce(function(a,b){a + b})
            //in_violation
        }

        //GET PEER
        getMessages = function (){
            checkSeen = function(peer){ // One peer
                peer_seen = ctx:query(peer{"Tx"}, "gossip", "seen_tracker")// Everything one peer has seen
                seen_diff = peer_seen.map(function(v,k){checkSeenDiff(v,k, peer{"Tx"})})
                seen_diff.values()
            }

            checkSeenDiff = function(value, key, peer_id){ // One thing one peer has seen
                check_seen = seen_tracker().map(function(v,k){getMessage(v,k,value,key, peer_id)})
                check_seen.values()
            }

            getMessage = function (value_origin, key_origin, value_peer, key_peer, peer_id){
                next_message = value_peer.as("Number") + 1
                messageId = peer_id + ":" + key_peer + ":" + next_message
                ret = (key_origin==key_peer && value_peer < value_origin) => messageId | null
                ret
            }

            peers = subs:established().filter(function(res){res{"Tx_role"}=="node"})
            peers_in_need = peers.map(function(res){checkSeen(res)}) // All Peers
            peers_in_need_reduced = peers_in_need.map(function(res){res.map(function(res){res.filter(function(ret){ret != null})})})
            possibleMessages = peers_in_need_reduced.map(function(ret){ret.filter(function(res){res.length() > 0})})
            possibleMessages.filter(function(res){res.length() > 0}).sort(function(a,b){a<=>b})
        }

        getViolationMessages = function (){
            checkSeen = function(peer){ // One peer
                peer_seen = ctx:query(peer{"Tx"}, "gossip", "violations_seen_tracker")// Everything one peer has seen
                seen_diff = peer_seen.map(function(v,k){checkSeenDiff(v,k, peer{"Tx"})})
                seen_diff.values()
            }

            checkSeenDiff = function(value, key, peer_id){ // One thing one peer has seen
                check_seen = violations_tracker().map(function(v,k){getMessage(v,k,value,key, peer_id)})
                check_seen.values()
            }

            getMessage = function (value_origin, key_origin, value_peer, key_peer, peer_id){
                next_message = value_peer.as("Number") + 1
                messageId = peer_id + ":" + key_peer + ":" + next_message
                ret = (key_origin==key_peer && value_peer < value_origin) => messageId | null
                ret
            }

            peers = subs:established().filter(function(res){res{"Tx_role"}=="node"})
            peers_in_need = peers.map(function(res){checkSeen(res)}) // All Peers
            peers_in_need_reduced = peers_in_need.map(function(res){res.map(function(res){res.filter(function(ret){ret != null})})})
            possibleMessages = peers_in_need_reduced.map(function(ret){ret.filter(function(res){res.length() > 0})})
            possibleMessages.filter(function(res){res.length() > 0}).sort(function(a,b){a<=>b})
        }

    }

    rule initialize {
        select when wrangler ruleset_installed
          where event:attr("rids") >< meta:rid

        always {
            ent:originID := random:uuid()
            ent:period := 5
            ent:seen_tracker := {}
            ent:message_tracker := {}
            ent:message_tracker{originID()} := {}
            ent:violations_seen_tracker := {}
            ent:violation_status := false
            ent:violations_tracker := {}
            ent:violations_tracker{originID()} := []
            ent:peers_seen_tracker := {}
            ent:sequence_number := -1
        }
    }

    rule start_heartbeat {
        select when gossip start_heartbeat
        pre {
            period = period()
        }
        always {
            schedule gossip event "gossip_heartbeat" repeat << */#{period} * * * * * >>
        }
    }

    rule gossip_heartbeat {
        select when gossip gossip_heartbeat

        pre {
            //Check if a node was connected - Happens in seperate rule
            messageToSend = getMessages()[0][0][0].klog("message")
            subscriber = messageToSend.split(re#:#)[0].klog("subscriber")
            messageSource = messageToSend.split(re#:#)[1].klog("source")
            messageNumber = messageToSend.split(re#:#)[2].klog("number")
            messageID = messageSource + ":" + messageNumber
            messageID_klog = messageID.klog("id")
            rumor = message_tracker().get([messageSource, messageID]).klog("rumor")
        }
        if(not rumor.isnull()) then
        event:send({"eci": subscriber,
                    "domain": "gossip", "name":"gossip_rumor",
                    "attrs": {
                        "message": rumor
                    }
        })
    }

    rule gossip_heartbeat_violations {
        select when gossip gossip_heartbeat

        pre {
            //Check if a node was connected - Happens in seperate rule
            messageToSend = getViolationMessages()[0][0][0].klog("message")
            subscriber = messageToSend.split(re#:#)[0].klog("subscriber")
            messageSource = messageToSend.split(re#:#)[1].klog("source")
            messageNumber = messageToSend.split(re#:#)[2].klog("number")
            messageID = messageSource + ":" + messageNumber
            messageID_klog = messageID.klog("id")
            rumor = (not messageSource.isnull()) => violations_tracker().get([messageSource]).slice(messageNumber, messageNumber).klog("rumor") | null
        }
        if(not messageSource.isnull()) then
        event:send({"eci": subscriber,
                    "domain": "gossip", "name":"gossip_violation",
                    "attrs": {
                        "message": rumor,
                        "source": messageSource,
                        "number": messageNumber
                    }
        })
    }

    rule gossip_rumor {
        select when gossip gossip_rumor

        pre{
            message = event:attrs{"message"}.klog()
            messageID = message{"MessageID"}.klog("id")
            messageSource = messageID.split(re#:#)[0].klog("source")
            messageNumber = messageID.split(re#:#)[1].klog("number")
        }
        if(not messageSource.isnull()) then
        noop()
        fired
        {
            ent:message_tracker{messageSource} := ent:message_tracker{messageSource}.put([messageID], message)
            ent:seen_tracker{messageSource} := messageNumber
        }
    }

    rule gossip_violation {
        select when gossip gossip_violation

        pre{
            message = event:attrs{"message"}.klog()
            messageSource = event:attrs{"source"}.klog()
            messageNumber = event:attrs{"number"}.klog()
        }
        if(not messageSource.isnull()) then
        noop()
        fired
        {
            ent:violations_tracker{messageSource} := ent:violations_tracker{messageSource}.append(message)
            ent:violations_seen_tracker{messageSource} := messageNumber
        }
    }

    rule gossip_seen {
        select when gossip gossip_seen

        pre{
            senderID = event:attrs{"senderID"}
            seen_message = event:attrs{"seen_message"}
        }
        always {
            ent:peers_seen_tracker{senderID} := seen_message
        }
    }

    rule collect_temp_messages {
        select when wovyn new_temperature_reading 

        pre {  
            seq_num = sequence_number() + 1
            messageID = originID() + ":" + seq_num
            temperature = event:attrs{"temperature"}[0]{"temperatureF"}
            timestamp = event:attrs{"timestamp"}
            collection = {"MessageID": messageID, "SensorID":originID(), "Temperature":temperature, "Timestamp":timestamp}
            violation_message = (temperature > sensor:threshold_temp() && violation_status() == false) => 1
                      | (temperature < sensor:threshold_temp() && violation_status() == true) => -1
                      | 0
            new_violation_status = (temperature > sensor:threshold_temp()) => true | false
        }
        always {
            ent:message_tracker{originID()} := ent:message_tracker{originID()}.put([messageID], collection)
            ent:violations_tracker{originID()} := ent:violations_tracker{originID()}.append(violation_message)
            ent:sequence_number := ent:sequence_number + 1
            ent:seen_tracker{originID()} := sequence_number()
            ent:violations_seen_tracker{originID()} := sequence_number()
            ent:violation_status := new_violation_status
            
        }
        
    }

    rule update_nodes {
        select when gossip gossip_heartbeat
        foreach all_peers_seen() setting(peer)
            foreach peer setting(value,id)
            pre {
                sensor_id = id.klog()
                exists = seen_tracker().filter(function(v,k){k==sensor_id}).klog()
            }
            if exists == {} then 
            noop()
            fired {
                ent:seen_tracker{id} := -1
                ent:message_tracker{id} := {}
                ent:violations_seen_tracker{id} := -1
                ent:violations_tracker{id} := []
            } else {
                log info "node already known"
            }
    }

}
