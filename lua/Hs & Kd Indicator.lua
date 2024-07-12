local Offsets = {
    m_pActionTrackingServices = GetOffset({ "client.dll", "classes", "CCSPlayerController", "fields", "m_pActionTrackingServices" }, "client.dll"),
    m_perRoundStats = GetOffset({ "client.dll", "classes", "CCSPlayerController_ActionTrackingServices", "fields", "m_perRoundStats" }, "client.dll"),
    m_iKills = GetOffset({ "client.dll", "classes", "CSPerRoundStats_t", "fields", "m_iKills" }, "client.dll"),
    m_iDeaths = GetOffset({ "client.dll", "classes", "CSPerRoundStats_t", "fields", "m_iDeaths" }, "client.dll"),
    m_iHeadShotKills = GetOffset({ "client.dll", "classes", "CSPerRoundStats_t", "fields", "m_iHeadShotKills" }, "client.dll"),
    m_pGameSceneNode = GetOffset({"client.dll", "classes", "C_BaseEntity", "fields", "m_pGameSceneNode"}, "client.dll"),
    m_vecAbsOrigin = GetOffset({"client.dll", "classes", "CGameSceneNode", "fields", "m_vecAbsOrigin"}, "client.dll"),
    m_iHealth = GetOffset({"client.dll", "classes", "C_BaseEntity", "fields", "m_iHealth"}, "client.dll"),
}

local function GetScoreboardInfo(EntityControllerAddress)
    local ActionTrackingServices = ReadPointer(EntityControllerAddress + Offsets.m_pActionTrackingServices) + Offsets.m_perRoundStats + 80
    local Kills = ReadInt(ActionTrackingServices + Offsets.m_iKills)
    local Deaths = ReadInt(ActionTrackingServices + Offsets.m_iDeaths)
    local HeadShotKills = ReadInt(ActionTrackingServices + Offsets.m_iHeadShotKills)
    local HsPercentage = 0
    if Kills ~= 0 then HsPercentage = math.floor(HeadShotKills / Kills * 100.0) end 
    if Deaths == 0 then Deaths = 1 end 
    return { HsPercentage, math.floor(Kills / Deaths * 100 + 0.5) / 100 }
end 

local ClientDLL = GetClientDLL()
local ScreenSize = GetScreenSize()

ReserveMenuElement(5) 
CheckBox("HS/KD Local", true)
SliderInt("HS/KD Local X", 1, ScreenSize[1], math.floor(ScreenSize[1] * 0.5) + 1)
SliderInt("HS/KD Local Y", 1, ScreenSize[2], math.floor(ScreenSize[2] * 0.11574074074))
CheckBox("KD Entity", true)
CheckBox("HS Entity", true)

local function Render()
    if not IsInGame() then return end 

    local LocalInfo = GetLocalInfo()

    if GetCheckBox("HS/KD Local") then 
        local StatData = GetScoreboardInfo(LocalInfo[2])
        local Padding = Vector2D(GetSliderInt("HS/KD Local X"), GetSliderInt("HS/KD Local Y"))
        local TempColor = 255 - math.floor(255 * StatData[1] * 0.01)
        local RedTint = Color(255, TempColor, TempColor, 255) 
        Rectangle(Vector2D(Padding[1] - 41, Padding[2] - 6), Vector2D(82, 32), RedTint, 5.0, 2.0)
        RectangleFilled(Vector2D(Padding[1] - 40, Padding[2] - 5), Vector2D(80, 30), Color(0, 0, 0, 200), 5.0, 15)
        Text(StatData[1] .. "% HS", Padding, RedTint, true)
        Padding[2] = Padding[2] + 10
        local Kd = StatData[2]
        if Kd > 2.5 then Kd = 2.5 end 
        TempColor = 255 - math.floor(255 * Kd * 0.4 * 100 * 0.01)
        RedTint = Color(255, TempColor, TempColor, 255) 
        Text(StatData[2] .. " KD", Padding, RedTint, true)
    end 

    local EntityList = GetEntities() 
    local SkipLocalTeam = GetConfigBool("SkipLocalTeam")
    local PlayerName = GetConfigBool("PlayerName")
    local HsEntity = GetCheckBox("HS Entity")
    local KdEntity = GetCheckBox("KD Entity")

    for i = 1, #EntityList do 
        if ReadInt(EntityList[i][1] + Offsets.m_iHealth) == 0 or (SkipLocalTeam and LocalInfo[4] == EntityList[i][4]) then goto continue end 

        local GameSceneNode = ReadPointer(EntityList[i][1] + Offsets.m_pGameSceneNode)
        if not GameSceneNode or GameSceneNode == 0 then goto continue end 

        local vecAbsOrigin = ReadVector3D(GameSceneNode + Offsets.m_vecAbsOrigin)
        if vecAbsOrigin[1] == 0 and vecAbsOrigin[2] == 0 and vecAbsOrigin[3] == 0 then goto continue end
        if PlayerName then vecAbsOrigin[3] = vecAbsOrigin[3] + 4 end 
        vecAbsOrigin[3] = vecAbsOrigin[3] + 72

        local ScreenPos = WorldToScreen(vecAbsOrigin)
        if ScreenPos[1] == 0 or ScreenPos[2] == 0 then goto continue end  
        if PlayerName then ScreenPos[2] = ScreenPos[2] - 5 end 
        ScreenPos[2] = ScreenPos[2] - 15

        local StatData = GetScoreboardInfo(EntityList[i][2])

        if HsEntity then 
            local TempColor = 255 - math.floor(255 * StatData[1] * 0.01)
            local RedTint = Color(255, TempColor, TempColor, 255) 
            Text(StatData[1] .. "% HS", ScreenPos, RedTint, true)
            ScreenPos[2] = ScreenPos[2] - 10
        end 

        if KdEntity then
            local Kd = StatData[2]
            if Kd > 2.5 then Kd = 2.5 end 
            local TempColor = 255 - math.floor(255 * Kd * 0.4 * 100 * 0.01)
            local RedTint = Color(255, TempColor, TempColor, 255) 
            Text(StatData[2] .. " KD", ScreenPos, RedTint, true)
        end 
        
        ::continue::
    end 
end 
RegisterCallback(Render)