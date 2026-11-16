local R = GuildRadioFM
local Wire = {}
R.Wire = Wire

local VERSION = "3"
local MAX_PACKET, MAX_BODY, MAX_AGE = 255, 220, 120
local BURST, RATE, MAX_PENDING = 8, 2, 64
local packets, received = {}, {}
local epoch, sequence, tokens, replenished = nil, 0, BURST, nil

local function refill()
    local now = GetTime()
    tokens = math.min(BURST, tokens + math.max(0, now - (replenished or now))*RATE)
    replenished = now
end

local function transmit(packet)
    local send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if not send then return false end
    local ok, result = pcall(send, packet.prefix, packet.body, packet.channel, packet.target)
    if not ok or result == false then return false end
    if type(result) == "number" then
        local values = Enum and Enum.SendAddonMessageResult
        return result == (values and values.Success or 0)
    end
    return true
end

function Wire.Flush()
    if #packets == 0 then return end
    refill()
    local now = GetTime()
    local guild = IsInGuild() and GetGuildInfo and GetGuildInfo("player") or nil
    while #packets > 0 do
        local packet = packets[1]
        if not guild or guild ~= packet.guild or now - packet.created > packet.ttl or
            (packet.valid and not packet.valid()) then
            table.remove(packets, 1)
        elseif tokens < 1 or (packet.retry and now < packet.retry) then
            break
        else
            tokens = tokens - 1
            if transmit(packet) then
                table.remove(packets, 1)
                if packet.onSent then packet.onSent() end
            else
                packet.retry = now + 2
                break
            end
        end
    end
end

function Wire.Send(prefix, body, channel, target, serverTime, onSent, valid)
    local guild = IsInGuild() and GetGuildInfo and GetGuildInfo("player")
    if not guild or #body > MAX_BODY then return false end
    if channel ~= "GUILD" and (channel ~= "WHISPER" or type(target) ~= "string" or target == "") then return false end
    if not epoch then
        epoch = math.max(math.floor(serverTime * 1000), (tonumber(R.db.eb.wireEpoch) or 0) + 1)
        R.db.eb.wireEpoch = epoch
    end
    sequence = sequence + 1
    local payload = VERSION .. "~" .. epoch .. "~" .. sequence .. "~" .. body
    if #payload > MAX_PACKET then return false end
    local kind = body:match("^[^~]+")
    local coalesce = kind == "LV" or kind == "QS" or kind == "TU"
    if coalesce then
        for i = #packets, 1, -1 do
            local prior = packets[i]
            if prior.kind == kind and prior.channel == channel and prior.target == target then table.remove(packets, i) end
        end
    end
    if #packets >= MAX_PENDING then return false end
    local transient = kind == "CH" or kind == "CR" or kind == "RR"
    packets[#packets + 1] = {prefix=prefix, body=payload, kind=kind, channel=channel, target=target,
        guild=guild, created=GetTime(), ttl=(transient or kind == "HO") and 8 or 30,
        onSent=onSent, valid=valid}
    Wire.Flush()
    return true
end

function Wire.Clear()
    packets, received = {}, {}
end

function Wire.Decode(packet, now)
    if type(packet) ~= "string" or #packet > MAX_PACKET then return end
    local version, session, number, body = packet:match("^(%d+)~(%d+)~(%d+)~(.+)$")
    if version ~= VERSION or not body or #body > MAX_BODY then return end
    session, number = tonumber(session), tonumber(number)
    if not session or not number or number < 1 or number > 1000000000 or session > (now + MAX_AGE)*1000 then return end
    return body, session, number
end

function Wire.Accept(sender, channel, stream, session, number)
    local key = sender .. "\031" .. channel .. "\031" .. stream
    local previous = received[key]
    if previous and (session < previous.session or
        (session == previous.session and number <= previous.number)) then return false end
    received[key] = {session=session, number=number}
    return true
end
