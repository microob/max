redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end

local clock = os.clock
function sleep(s)
  local delay = redis:get("botBOT-IDdelay") or 5
  local randomdelay = math.random (tonumber(delay)- (tonumber(delay)/2), tonumber(delay)+ (tonumber(delay)/2))
  local t0 = clock()
  while clock() - t0 <= tonumber(randomdelay) do end
end

function get_admin ()
  if redis:get('botBOT-IDadminset') then
    return true
  else
    print("sudo id :")
    admin=io.read()
    redis:del("botBOT-IDadmin")
    redis:sadd("botBOT-IDadmin", admin)
    redis:set('botBOT-IDadminset',true)
  end
  return print("Owner: ".. admin)
end
function get_bot (i, adigram)
  function bot_info (i, adigram)
    redis:set("botBOT-IDid",adigram.id_)
    if adigram.first_name_ then
      redis:set("botBOT-IDfname",adigram.first_name_)
    end
    if adigram.last_name_ then
      redis:set("botBOT-IDlanme",adigram.last_name_)
    end
    redis:set("botBOT-IDnum",adigram.phone_number_)
    return adigram.id_
  end
  tdcli_function ({ID = "GetMe",}, bot_info, nil)
  end
  function is_adigram(msg)
    local var = false
    local hash = 'botBOT-IDadmin'
    local user = msg.sender_user_id_
    local Adigram = redis:sismember(hash, user)
    if Adigram then
      var = true
    end
    return var
  end
  function writefile(filename, input)
    local file = io.open(filename, "w")
    file:write(input)
    file:flush()
    file:close()
    return true
  end
  function process_join(i, adigram)
    if adigram.code_ == 429 then
      local message = tostring(adigram.message_)
      local Time = message:match('%d+')
      redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
    else
      redis:srem("botBOT-IDgoodlinks", i.link)
      redis:sadd("botBOT-IDsavedlinks", i.link)
    end
  end
  function process_link(i, adigram)
    if (adigram.is_group_ or adigram.is_supergroup_channel_) then
      redis:srem("botBOT-IDwaitelinks", i.link)
      redis:sadd("botBOT-IDgoodlinks", i.link)
    elseif adigram.code_ == 429 then
      local message = tostring(adigram.message_)
      local Time = message:match('%d+')
      redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
    else
      redis:srem("botBOT-IDwaitelinks", i.link)
    end
  end
  function find_link(text)
    if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
      local text = text:gsub("t.me", "telegram.me")
      local text = text:gsub("telegram.dog", "telegram.me")
      for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
        if not redis:sismember("botBOT-IDalllinks", link) then
          redis:sadd("botBOT-IDwaitelinks", link)
          redis:sadd("botBOT-IDalllinks", link)
        end
      end
    end
  end
  function add(id)
    local Id = tostring(id)
    if not redis:sismember("botBOT-IDall", id) then
      if Id:match("^(%d+)$") then
        redis:sadd("botBOT-IDusers", id)
        redis:sadd("botBOT-IDall", id)
      elseif Id:match("^-100") then
        redis:sadd("botBOT-IDsupergroups", id)
        redis:sadd("botBOT-IDall", id)
      else
        redis:sadd("botBOT-IDgroups", id)
        redis:sadd("botBOT-IDall", id)
      end
    end
    return true
  end
  function rem(id)
    local Id = tostring(id)
    if redis:sismember("botBOT-IDall", id) then
      if Id:match("^(%d+)$") then
        redis:srem("botBOT-IDusers", id)
        redis:srem("botBOT-IDall", id)
      elseif Id:match("^-100") then
        redis:srem("botBOT-IDsupergroups", id)
        redis:srem("botBOT-IDall", id)
      else
        redis:srem("botBOT-IDgroups", id)
        redis:srem("botBOT-IDall", id)
      end
    end
    return true
  end
  function send(chat_id, msg_id, text)
    tdcli_function ({
          ID = "SendMessage",
          chat_id_ = chat_id,
          reply_to_message_id_ = msg_id,
          disable_notification_ = 1,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = text,
            disable_web_page_preview_ = 1,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {ID = "TextParseModeHTML"},
          },
          }, dl_cb, nil)
    end
    get_admin()
    function tdcli_update_callback(data)
      if data.ID == "UpdateNewMessage" then
        if not redis:get("botBOT-IDmaxlink") then
          if redis:scard("botBOT-IDwaitelinks") ~= 0 then
            local links = redis:smembers("botBOT-IDwaitelinks")
            for x,y in pairs(links) do
              if x == 11 then redis:setex("botBOT-IDmaxlink", 60, true) return end
              tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
              end
            end
          end
          if not redis:get("botBOT-IDmaxjoin") then
            if redis:scard("botBOT-IDgoodlinks") ~= 0 then 
              local links = redis:smembers("botBOT-IDgoodlinks")
              for x,y in pairs(links) do
                local sgps = redis:scard("botBOT-IDsupergroups")
                local maxsg = redis:get("botBOT-IDmaxsg") or 200
                if tonumber(sgps) < tonumber(maxsg) then
                  tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
                    if x == 4 then redis:setex("botBOT-IDmaxjoin", 60, true) return end
                  end
                end
              end
            end
           
                        elseif text:match("s") or text:match("p") then
                          local gps = redis:scard("botBOT-IDgroups")
                          local sgps = redis:scard("botBOT-IDsupergroups")
                          local usrs = redis:scard("botBOT-IDusers")
                          local links = redis:scard("botBOT-IDsavedlinks")
                          local glinks = redis:scard("botBOT-IDgoodlinks")
                          local wlinks = redis:scard("botBOT-IDwaitelinks")
                          local s = redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
                          local ss = redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
                          local delay = redis:get("botBOT-IDdelay") or 5
                          local maxsg = redis:get("botBOT-IDmaxsg") or 200

                          local text = 
[[<b> stats </b>
➖➖➖➖➖
<code> superGPs: </code>
 <b>]] .. tostring(sgps) .. [[</b><code> superGP</code> 


                        
                                  elseif msg.content_.ID == "MessageContact" then
                                    if redis:sismember("botBOT-IDadmin",msg.sender_user_id_) then
                                      local first = msg.content_.contact_.first_name_ or "-"
                                      local last = msg.content_.contact_.last_name_ or "-"
                                      local phone = msg.content_.contact_.phone_number_
                                      local id = msg.content_.contact_.user_id_
                                      tdcli_function ({
                                            ID = "ImportContacts",
                                            contacts_ = {[0] = {
                                                phone_number_ = tostring(phone),
                                                first_name_ = tostring(first),
                                                last_name_ = tostring(last),
                                                user_id_ = id
                                              },
                                            },
                                            }, dl_cb, nil)
                                        return send (msg.chat_id_, msg.id_, "<code> Added </code>\n➖➖➖\n")
                                      end
                                    elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
                                      return rem(msg.chat_id_)
                                    elseif msg.content_.ID == "MessageChatJoinByLink" and msg.sender_user_id_ == bot_id then
                                      return add(msg.chat_id_)
                                    elseif msg.content_.ID == "MessageChatAddMembers" then
                                      for i = 0, #msg.content_.members_ do
                                        if msg.content_.members_[i].id_ == bot_id then
                                          add(msg.chat_id_)
                                        end
                                      end
                                    elseif msg.content_.caption_ then
                                      return find_link(msg.content_.caption_)
                                    end
                                    if redis:get("botBOT-IDmarkread") then
                                      tdcli_function ({
                                            ID = "ViewMessages",
                                            chat_id_ = msg.chat_id_,
                                            message_ids_ = {[0] = msg.id_} 
                                            }, dl_cb, nil)
                                      end
                                    elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
                                      tdcli_function ({
                                            ID = "GetChats",
                                            offset_order_ = 9223372036854775807,
                                            offset_chat_id_ = 0,
                                            limit_ = 20
                                            }, dl_cb, nil)
                                      end
                                    end

