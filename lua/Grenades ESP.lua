local ClientDLL = GetClientDLL()

local Offsets = {
	m_pGameSceneNode = GetOffset({ "client.dll", "classes", "C_BaseEntity", "fields", "m_pGameSceneNode" }, "client.dll"),
	m_vecAbsOrigin = GetOffset({ "client.dll", "classes", "CGameSceneNode", "fields", "m_vecAbsOrigin" }, "client.dll"),
	dwEntityList = GetOffset({ "client.dll", "dwEntityList" }, "offsets"),
	m_pEntity = GetOffset({ "client.dll", "classes", "CEntityInstance", "fields", "m_pEntity" }, "client.dll"),
	m_designerName = GetOffset({ "client.dll", "classes", "CEntityIdentity", "fields", "m_designerName" }, "client.dll"),
	m_iState = GetOffset({ "client.dll", "classes", "C_CSWeaponBase", "fields", "m_iState" }, "client.dll"),
}

local ScreenCenter = Vector2D(math.floor(GetScreenSize()[1] / 2), math.floor(GetScreenSize()[2] / 2))
local Grenades = {}

ReserveMenuElement(19)
CreateText("\n")
CreateText("ESP")
CheckBox("Line ESP", false)
CheckBox("Circle", false)
CheckBox("Icon", false)
CheckBox("Name", false)
CreateText("\n")
CreateText("Colors")
ColorPicker("Line Color", Color(255, 255, 255, 255))
ColorPicker("Circle Color", Color(255, 255, 255, 255))
ColorPicker("Icon Color", Color(255, 255, 255, 255))
ColorPicker("Name Color", Color(255, 255, 255, 255))
CreateText("\n")
CreateText("Misc")
SliderFloat("Max Distance", 1.0, 10000.0, 10000.0)
SliderFloat("Circle Radius", 1.0, 40.0, 5.0)
SliderFloat("Line Thickness", 0.1, 10.0, 1.0)
SliderInt("Icon Size", 0, 10, 5)
CreateText("\n")

local GrenadeTypes = {
	["weapon_smokegrenade"] = { "Smoke", 45 },
	["smokegrenade_projectile"] = { "Smoke", 45 },
	["weapon_flashbang"] = { "Flash", 43 },
	["flashbang_projectile"] = { "Flash", 43 },
	["weapon_hegrenade"] = { "HE", 44 },
	["hegrenade_projectile"] = { "HE", 44 },
	["weapon_molotov"] = { "Molotov", 46 },
	["molotov_projectile"] = { "Molotov", 46 },
	["weapon_incgrenade"] = { "Incendiary", 48 },
	["incgrenade_projectile"] = { "Incendiary", 48 },
	["weapon_decoy"] = { "Decoy", 47 },
	["decoy_projectile"] = { "Decoy", 47 }
}

local function FindEntities()
	local EntityList = ReadPointer(ClientDLL + Offsets.dwEntityList)

	if EntityList == 0 then
		return
	end 

	for i = 1, 1024 do
		local ListEntry = ReadPointer(EntityList + 8 * ((i & 0x7FFF) >> 9) + 16)
		
		if ListEntry == 0 then
			goto continue
		end

		local BaseEntity = ReadPointer(ListEntry + 120 * (i & 0x1FF))

		if BaseEntity == 0 then
			goto continue
		end

		local pEntity = ReadPointer(BaseEntity + Offsets.m_pEntity)

		if pEntity == 0 then
			goto continue
		end

		local designerName = ReadPointer(pEntity + Offsets.m_designerName)

		if designerName == 0 then
			goto continue
		end

		local grenadeType = GrenadeTypes[tostring(ReadString(designerName))]

		if grenadeType == nil then
			goto continue
		end

		local m_iStateValue = ReadInt(BaseEntity + Offsets.m_iState)

		if m_iStateValue == 1 or m_iStateValue == 2 then
			goto continue
		end 

		table.insert(Grenades, { BaseEntity, grenadeType })

		::continue::
	end
end 

local function DrawGrenades()
	Grenades = {}

	FindEntities()

	local localAbsOrigin = ReadVector3D(ReadPointer(GetLocalInfo()[1] + Offsets.m_pGameSceneNode) + Offsets.m_vecAbsOrigin)
	local MaxDistance = GetSliderFloat("Max Distance")
	local LineESP = GetCheckBox("Line ESP")
	local LineColor = GetColorPicker("Line Color")
	local LineThickness = GetSliderFloat("Line Thickness")
	local Circle = GetCheckBox("Circle")
	local CircleRadius = GetSliderFloat("Circle Radius")
	local CircleColor = GetColorPicker("Circle Color")
	local Name = GetCheckBox("Name")
	local NameColor = GetColorPicker("Name Color")
	local b_Icon = GetCheckBox("Icon")
	local IconColor = GetColorPicker("Icon Color")
	local IconSize = GetSliderInt("Icon Size")

	for i, grenadeData in ipairs(Grenades) do
		local GameSceneNode = ReadPointer(grenadeData[1] + Offsets.m_pGameSceneNode)

		if GameSceneNode == 0 then
			goto continue
		end

		local vecAbsOrigin = ReadVector3D(GameSceneNode + Offsets.m_vecAbsOrigin)

		if math.sqrt((localAbsOrigin[1] - vecAbsOrigin[1]) ^ 2 + (localAbsOrigin[2] - vecAbsOrigin[2]) ^ 2 + (localAbsOrigin[3] - vecAbsOrigin[3]) ^ 2) > MaxDistance then
			goto continue
		end

		local SmokePos = Vector3D(vecAbsOrigin[1], vecAbsOrigin[2], vecAbsOrigin[3])
		local ScreenPos = WorldToScreen(SmokePos)

		if ScreenPos[1] == 0 and ScreenPos[2] == 0 then
			goto continue
		end

		if LineESP then
			Line(ScreenPos, Vector2D(ScreenCenter[1], ScreenCenter[2]), LineColor, LineThickness)
		end

		if Circle then
			Circle3D(SmokePos, CircleRadius, 2.0, CircleColor)
		end

		if Name then
			ScreenPos[2] = ScreenPos[2] + 10
			Text(grenadeData[2][1], ScreenPos, NameColor, true)
		end 

		if b_Icon then
			local ScreenIconPos = WorldToScreen(Vector3D(vecAbsOrigin[1], vecAbsOrigin[2], math.floor(vecAbsOrigin[3] + 10)))

			if ScreenIconPos[1] == 0 and ScreenIconPos[2] == 0 then
				goto continue
			end

			ScreenIconPos[2] = ScreenIconPos[2] - 10

			Icon(grenadeData[2][2], ScreenIconPos, IconColor, true, IconSize)
		end 

		::continue::
	end
end 
RegisterCallback(DrawGrenades)