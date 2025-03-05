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
    task.spawn(function()
        while true do
            -- Detect if someone is modifying the script
            if tick() - startTime > 2 and not game:IsLoaded() then
                local message = "🚨 CRACK ATTEMPT DETECTED! 🚨\n👤 Username: " .. playerName .. "\n🆔 UserID: " .. playerId
                warn(message)

                -- 🚨 Send Webhook Alert
                local success, response = pcall(function()
                    return httpService:PostAsync(webhookUrl, httpService:JSONEncode({ content = message }), Enum.HttpContentType.ApplicationJson)
                end)

                if not success then
                    warn("❌ Webhook failed: " .. tostring(response))
                end

                error("Tampering detected! You are now permanently banned.")
            end
            task.wait(1)
        end
    end)
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
