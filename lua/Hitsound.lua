Clear()

local OldHits = 0
local HitsoundPath = GetAppDataDirectory() .. "\\Hitsound.wav"
local m_pBulletServices = GetOffset({"client.dll", "classes", "C_CSPlayerPawn", "fields", "m_pBulletServices"}, "client.dll")
local m_totalHitsOnServer = GetOffset({"client.dll", "classes", "CCSPlayer_BulletServices", "fields", "m_totalHitsOnServer"}, "client.dll")
local m_iHealth = GetOffset({"client.dll", "classes", "C_BaseEntity", "fields", "m_iHealth"}, "client.dll")

if not DirectoryExists(HitsoundPath) then 
    Print("[-] Attempting to download hitsound file...")
    HttpDownload("https://github.com//ZirczWare//CS2-Orbit-Resources//raw//main//flick.wav", HitsoundPath)

    if not DirectoryExists(HitsoundPath) then 
        Print("[-] Failed to download hitsound file.")
        Print("[-] Make sure Http Functions are enabled.")
        return 
    else
        Print("[-] Hitsound downloaded.")
    end 
end 

Print("[-] Ultimate hitsound script loaded.")

local function HitSound()
    if not IsInGame() then 
        return 
    end 

    local LocalPawn = GetLocalInfo()[1]

    if ReadInt(LocalPawn + m_iHealth) == 0 then 
        return 
    end 

    local TotalHitsOnServer = ReadInt(ReadPointer(LocalPawn + m_pBulletServices) + m_totalHitsOnServer)

    if TotalHitsOnServer ~= OldHits and TotalHitsOnServer ~= 0 then 
        OldHits = TotalHitsOnServer
        PlaySound(HitsoundPath)
    elseif TotalHitsOnServer == 0 and OldHits ~= 0 then 
        OldHits = 0
    end 
end 
RegisterCallback(HitSound)