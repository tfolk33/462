ruleset gossip {
    meta {
      name "Gossip"
      author "Tanner Folkman"
      description <<
        An Rulest for Lab9
      >>

      use module io.picolabs.subscription alias subs

      provides period, originID, sequence_number, message_tracker, seen_tracker, getMessages, all_peers_seen, peers_seen_tracker
      shares period, originID, sequence_number, message_tracker, seen_tracker, getMessages, all_peers_seen, peers_seen_tracker
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

    rule gossip_rumor {
        select when gossip gossip_rumor

        pre{
            message = event:attrs{"message"}.klog()
            messageID = message{"MessageID"}.klog("id")
            messageSource = messageID.split(re#:#)[0].klog("source")
            messageNumber = messageID.split(re#:#)[1].klog("number")
        }
        always
        {
            ent:message_tracker{messageSource} := ent:message_tracker{messageSource}.put([messageID], message)
            ent:seen_tracker{messageSource} := messageNumber
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
        }
        always {
            ent:message_tracker{originID()} := ent:message_tracker{originID()}.put([messageID], collection)
            ent:sequence_number := ent:sequence_number + 1
            ent:seen_tracker{originID()} := sequence_number()
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
            } else {
                log info "node already known"
            }
    }

}
