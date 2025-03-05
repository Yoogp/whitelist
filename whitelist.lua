local httpService = game:GetService("HttpService")
local players = game:GetService("Players")

local localPlayer = players.LocalPlayer
local playerName = localPlayer.Name
local playerId = localPlayer.UserId

local webhookUrl = settings.whitelist.AntiCrack.WebhookURL
local banListUrl = settings.whitelist.RemoteBans.BanListURL
local githubToken = settings.whitelist.SaveWhitelistedUsers.GitHubToken
local githubRepo = settings.whitelist.SaveWhitelistedUsers.GitHubRepo

local function decryptData(data)
    return syn and syn.crypt.base64.decode(data) or data
end

local function checkRemoteBans()
    if not settings.whitelist.RemoteBans.Enabled then return end

    local bannedList = game:HttpGet(settings.whitelist.RemoteBans.BanListURL, true)
    local playerID = game.Players.LocalPlayer.UserId

    if string.find(bannedList, tostring(playerID)) then
        error("You are banned from using this script.")
    end
end

local function detectTampering()
    local startTime = tick()
    while true do
        if tick() - startTime > 2 then
            local message = "🚨 CRACK ATTEMPT DETECTED! 🚨\n👤 Username: " .. playerName .. "\n🆔 UserID: " .. playerId
            warn(message)

            -- 🚨 1. Send Webhook Alert
            local data = httpService:JSONEncode({ content = message })
            httpService:PostAsync(webhookUrl, data, Enum.HttpContentType.ApplicationJson)

            -- 🚨 2. Auto-Ban Player by Adding to GitHub Ban List
            local bannedList = game:HttpGet(banListUrl, true)
            if not string.find(bannedList, tostring(playerId)) then
                local newBanList = bannedList .. "\n" .. playerId .. " -- " .. playerName
                local requestUrl = "https://api.github.com/repos/" .. githubRepo .. "/contents/banned_users.txt"

                local requestBody = httpService:JSONEncode({
                    message = "Auto-ban: " .. playerName,
                    content = httpService:Base64Encode(newBanList),
                    sha = game:HttpGet(requestUrl, true):match('"sha":%s-"([^"]+)"')
                })

                httpService:RequestAsync({
                    Url = requestUrl,
                    Method = "PUT",
                    Headers = {
                        ["Authorization"] = "token " .. githubToken,
                        ["Content-Type"] = "application/json"
                    },
                    Body = requestBody
                })
            end

            error("Tampering detected! You are now permanently banned.")
        end
        wait(0.1)
    end
end

-- 🚀 Activate Anti-Crack System
if settings.whitelist.AntiCrack.DetectTampering then
    task.spawn(detectTampering)
end

local function verifyHWID()
    local success, encryptedHWIDList = pcall(function()
        return game:HttpGet(settings.whitelist.HWIDSource.URL, true)
    end)

    if not success then
        error("Failed to fetch HWID list.")
    end

    local hwidList = settings.whitelist.HWIDSource.Encrypted and decryptData(encryptedHWIDList) or encryptedHWIDList
    local success, hwidTable = pcall(function()
        return httpService:JSONDecode(hwidList)
    end)

    if not success then
        error("HWID list is not in JSON format.")
    end

    local playerHWID = game:GetService("RbxAnalyticsService"):GetClientId()
    
    if not table.find(hwidTable, playerHWID) then
        error("Unauthorized access! Your HWID is not whitelisted.")
    end
end

checkRemoteBans()
verifyHWID()

loadstring(game:HttpGet("https://raw.githubusercontent.com/Yoogp/whitelist/refs/heads/main/mainscript"))()
