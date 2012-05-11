### 
# Parse Messages from a Skype conversation in to a JSON Object.
# jens a. ewald, ififelse.net, 2012, licensed by the unlicence
###

String::parsefromSkype = ->
  # The parser must be different for Windows or Mac Version.  
  # Linux is not tested yet.
  #
  # On Windows the input looks something like this:
  # 
  #   > [06.05.2009 17:25:06] Jane Doe: Howdy! ...  
  #   > [06.05.2009 17:26:10] John Doe: Oh! Hi Jane, nic...  
  #   > [06.05.2009 17:28:28] John Doe: How's the weath...  
  # 
  # The Mac Version gives you more this style:
  # 
  #   > Jane Doe 28.10.11 12:31  
  #   > Howdy! Nice to see you!  
  #   > John Doe 28.10.11 12:31  
  #   > Oh! Hi Jane, nice weather today, isn't it  
  #   > 28.10.11 12:31  
  #   > How's the weather in Australia?  
  #
  
  # _Store the platform flag for later use!_
  # So, we can dissect it with two different RegExp.
  platform_is_windows = @.match /^\[\d{2}/
  
  # #### The RegExp for Windows style messages
  parser = if platform_is_windows
    ///
      # First find the time!
      (
        \[
          (\d{2}:\d{2}:\d{2})
        \]
      )
      # Time and the actual message are always seperated with a space!
      \s
      (
        # The message can be just a message ...
        (
          # so, we  have users name
          (.+)
          # which is seperated with a colon and a space
          :\s
          # from the message text (which runs across multiple lines)
          ([\s\S]+?)
        )
        | # ... or we have a state change / sysex message
        (
          # which starts with 3 asterix'
          (\*{3})\s
          (
            # then it can be a new user by an existing user
            ((.+)\shat\s(.+?)\shinzu.+)
            |
            # or the topic has been changed by an existing user.
            ((.+)\shat\sdas\s(Thema).+\sin\s"(.+)")
          )
          # Afterwards the sysex closes with 3 asterix' again.
          \s\*{3}
        )
      )
      # As each message block is either followed by a line break and a new time
      # tag or the end of the string, we look ahead for it:
      (?=(\r\n\[\d{2}:\d{2}:\d{2}\])|$)
    ///g
  else
    # #### The RegExp for Mac style messages
    ///
      (
        (
          # Meta information
          (
            # Username
            (.*)\s
            # Date
            (
              (\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+)
            )
            (?=\s|\n)
          )
          # The message itself
          (
            (.|(\n(?!.*\d{2}\.)))+
          )
        )
      )
    ///g
  
  
  # With the parser RegExp and the platform flag we can parse the message string, 
  # build a collection object and return it.
  while _result = parser.exec @
    # For each platform the resulting array is a bit different, so we
    # must collect from different positions.
    keys = if platform_is_windows then [3,4,5,7,8,9,10,11] else [6,7,8,9,10,4,11]
    _res = (e for k,e of _result when parseInt(k) in keys)
    console.log _result
    if platform_is_windows
      [d,mo,y,h,m,s,user,message] = _res
    else
      [user,d,mo,y,h,m,message]   = _res
      # **Warning! Unprecise stuff.** 
      # The Mac-Skype timestamp does not give us a full year. So we must guess.
      y = "20#{y}"
    
    topic = message?.getSkypeTopic() ? ""
    
    # Finally we can build a new object
    _conversation_partial =
      User: user || lastuser,
      Zeit: new Date(y,mo,d,h,m,(s ? 0)) || lasttime,
      Text: message,
      Kommentar: ""
      Thema: topic || lasttopic
    
    # Keep last used unstable properties as fallback properties
    lastuser  = _conversation_partial.User
    lasttime  = _conversation_partial.Zeit
    lasttopic = _conversation_partial.Thema
    
    # Return the parsed object
    _conversation_partial


###
# Retrieve a topic change from a message
###
String::getSkypeTopic = ->
  res = @.match ///
    \[ 
    # Date
      # \d{2}.\d{2}.\d{4}
      # \s
    # Time
      \d{2}\:\d{2}\:\d{2}
    \]\s
    \*{3}.*Thema.*"(.+)".*\*{3}
  ///
  if res.length? and res.length>1 then res[1] else null

