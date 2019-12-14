--[[------------------------------------------------------------------

  CONFIGURATION

]]--------------------------------------------------------------------

-- Parameters
local HIGHLIGHT_COLOR = Color(155, 20, 121, 100); -- Highlighted items color
local UNHIGHLIGHTED_COLOR = Color(100, 100, 100, 100); -- Unhighlighted items color
local COLOR_CONVAR = "matrixwepsel_col";
local UNHIGHLIGHTED_COLOR_CONVAR = "matrixwepsel_col_u";

-- Console variables
local isEnabled = CreateClientConVar("matrixwepsel_enabled", 1, true, nil, "Enables the Matrix's Weapon Selector");

--[[------------------------------------------------------------------
	Creates a set of convars to set a color
	@param {string} name
	@param {Color} color
	@return {table} red convar
	@return {table} green convar
	@return {table} blue convar
	@return {table} alpha convar
]]--------------------------------------------------------------------
local function CreateColorConVar(name, color)
	return CreateClientConVar(name .. "_r", color.r, true),
				 CreateClientConVar(name .. "_g", color.g, true),
				 CreateClientConVar(name .. "_b", color.b, true),
				 CreateClientConVar(name .. "_a", color.a, true);
end

local color_r, color_g, color_b, color_a = CreateColorConVar(COLOR_CONVAR, HIGHLIGHT_COLOR);
local color_u_r, color_u_g, color_u_b, color_u_a = CreateColorConVar(UNHIGHLIGHTED_COLOR_CONVAR, UNHIGHLIGHTED_COLOR);

--[[------------------------------------------------------------------
	Resets a color to default
	@param {string} name
	@param {Color} color
]]--------------------------------------------------------------------
local function ResetColor(name, color)
	RunConsoleCommand(name .. "_r", color.r);
	RunConsoleCommand(name .. "_g", color.g);
	RunConsoleCommand(name .. "_b", color.b);
	RunConsoleCommand(name .. "_a", color.a);
end

--[[------------------------------------------------------------------
	Whether the weapon selector is enabled
	@return {boolean} is enabled
]]--------------------------------------------------------------------
local function IsEnabled()
	return isEnabled:GetInt() >= 1;
end

--[[------------------------------------------------------------------
	Gets the highlighted items color
	@return {Color} highlighted items color
]]--------------------------------------------------------------------
local function GetHighlightColor()
	return Color(color_r:GetInt(), color_g:GetInt(), color_b:GetInt(), color_a:GetInt());
end

--[[------------------------------------------------------------------
	Gets the unhighlighted items color
	@return {Color} unhighlighted items color
]]--------------------------------------------------------------------
local function GetUnhighlightedColor()
	return Color(color_u_r:GetInt(), color_u_g:GetInt(), color_u_b:GetInt(), color_u_a:GetInt());
end

--[[------------------------------------------------------------------
	Resets to default all colors
]]--------------------------------------------------------------------
concommand.Add("matrixwepsel_reset", function(ply, com, args)
	ResetColor(COLOR_CONVAR, HIGHLIGHT_COLOR);
	ResetColor(UNHIGHLIGHTED_COLOR_CONVAR, UNHIGHLIGHTED_COLOR);
end);

--[[------------------------------------------------------------------
	Create menu
]]--------------------------------------------------------------------
hook.Add( "PopulateToolMenu", "vgntk_menu", function()
	spawnmenu.AddToolMenuOption( "Options", "Selenter1", "matrixwepsel", "Matrix Weapon Selector", nil, nil, function(panel)
		panel:ClearControls();

		panel:AddControl( "CheckBox", {
			Label = "Enabled",
			Command = "matrixwepsel_enabled",
			}
		);

		panel:AddControl( "Color", {
			Label = "Highlighted item color",
			Red = COLOR_CONVAR .. "_r",
			Green = COLOR_CONVAR .. "_g",
			Blue = COLOR_CONVAR .. "_b",
			Alpha = COLOR_CONVAR .. "_a"
			}
		);

		panel:AddControl( "Color", {
			Label = "Unhighlighted item color",
			Red = UNHIGHLIGHTED_COLOR_CONVAR .. "_r",
			Green = UNHIGHLIGHTED_COLOR_CONVAR .. "_g",
			Blue = UNHIGHLIGHTED_COLOR_CONVAR .. "_b",
			Alpha = UNHIGHLIGHTED_COLOR_CONVAR .. "_a"
			}
		);

		panel:AddControl( "Button", {
			Label = "Reset settings to default",
			Command = "matrixwepsel_reset",
			}
		);
	end );
end);

--[[------------------------------------------------------------------

  DRAW WEAPON SELECTOR

]]--------------------------------------------------------------------
function NewDrawText(text, x, y, color, alignX, alignY, font, alpha)
	color = color or color_white

	return draw.TextShadow({
		text = text,
		font = "NewWeaponSelectFont",
		pos = {x, y},
		color = color,
		xalign = alignX or TEXT_ALIGN_LEFT,
		yalign = alignY or TEXT_ALIGN_LEFT
	}, 1, alpha or (color.a * 0.575))
end

--if (CLIENT) then
	surface.CreateFont("NewWeaponSelectFont", {
		font = "Roboto Th",
		size = ScreenScale(16),
		--extended = true,
		weight = 500
	})
	NewWeaponSelecter = {}
	NewWeaponSelecter.index = NewWeaponSelecter.index or 1
	NewWeaponSelecter.deltaIndex = NewWeaponSelecter.deltaIndex or NewWeaponSelecter.index
	NewWeaponSelecter.infoAlpha = NewWeaponSelecter.infoAlpha or 0
	NewWeaponSelecter.alpha = NewWeaponSelecter.alpha or 0
	NewWeaponSelecter.alphaDelta = NewWeaponSelecter.alphaDelta or NewWeaponSelecter.alpha
	NewWeaponSelecter.fadeTime = NewWeaponSelecter.fadeTime or 0
	NewWeaponSelecter.weapons = NewWeaponSelecter.weapons or {}

	hook.Add( "HUDShouldDraw", "NewWeaponSelecter_ShouldDraw", function(name)
		if (name == "CHudWeaponSelection" and IsEnabled()) then
			return false
		end
	end)

	hook.Add( "HUDPaint", "NewWeaponSelecter_HUDPaint", function()
		if (not IsEnabled()) then return end
		local frameTime = FrameTime()

		NewWeaponSelecter.alphaDelta = Lerp(frameTime * 10, NewWeaponSelecter.alphaDelta, NewWeaponSelecter.alpha)

		local fraction = NewWeaponSelecter.alphaDelta

		if (fraction > 0.01) then
			local x, y = 100, ScrH() * .4
			local spacing = ScrH() / 380 -- originally (math.pi * 0.6)
			local radius = 240 * NewWeaponSelecter.alphaDelta
			local shiftX = ScrW() * .02

			NewWeaponSelecter.deltaIndex = Lerp(frameTime * 12, NewWeaponSelecter.deltaIndex, NewWeaponSelecter.index)

			local index = NewWeaponSelecter.deltaIndex

			if (!NewWeaponSelecter.weapons[NewWeaponSelecter.index]) then
				NewWeaponSelecter.index = #NewWeaponSelecter.weapons
			end

			for i = 1, #NewWeaponSelecter.weapons do
				local theta = (i - index) * 0.1

				local color2 = i == NewWeaponSelecter.index and GetHighlightColor() or GetUnhighlightedColor();
				color2.a = (color2.a - math.abs(theta * 3) * color2.a) * fraction

				local color3 = ColorAlpha(
					i == NewWeaponSelecter.index and Color(255, 255, 255, 255) or Color(255, 255, 255, 255),
					(255 - math.abs(theta * 3) * 255) * fraction
				)

				local ebatTextKruto = i == NewWeaponSelecter.index and 10 + math.sin(CurTime()*4) * 5 or 10

				local lastY = 0

				if (NewWeaponSelecter.markup and (i < NewWeaponSelecter.index or i == 1)) then
					if (NewWeaponSelecter.index != 1) then
						local _, h = NewWeaponSelecter.markup:Size()
						lastY = h * fraction
					end

					if (i == 1 or i == NewWeaponSelecter.index - 1) then
						NewWeaponSelecter.infoAlpha = Lerp(frameTime * 3, NewWeaponSelecter.infoAlpha, 255)
						NewWeaponSelecter.markup:Draw(x + 6 + shiftX, y + 30, 0, 0, NewWeaponSelecter.infoAlpha * fraction)
					end
				end

				surface.SetFont("NewWeaponSelectFont")
				local weaponName = NewWeaponSelecter.weapons[i]:GetPrintName():upper()
				local _, ty = surface.GetTextSize(weaponName)
				local scale = 1 - math.abs(theta * 2)

				local matrix = Matrix()
				matrix:Translate(Vector(
					shiftX + x + math.cos(theta * spacing + math.pi) * radius + radius,
					y + lastY + math.sin(theta * spacing + math.pi) * radius - ty / 2,
					1))
				matrix:Scale(Vector(1, 1, 0) * scale)

				cam.PushModelMatrix(matrix)
					NewDrawText(weaponName, ebatTextKruto, ty / 2 - 1, color3, 0, 1, "NewWeaponSelectFont")
					if i > NewWeaponSelecter.index - 4 and i < NewWeaponSelecter.index + 4 then
					surface.SetTexture(surface.GetTextureID("vgui/gradient-l"))
					surface.SetDrawColor(color2)
					surface.DrawTexturedRect(0, 0, 400, ScreenScale(16))
					end
				cam.PopModelMatrix()
			end

			if (NewWeaponSelecter.fadeTime < CurTime() and NewWeaponSelecter.alpha > 0) then
				NewWeaponSelecter.alpha = 0
			end
		elseif (#NewWeaponSelecter.weapons > 0) then
			NewWeaponSelecter.weapons = {}
		end
	end)

	function OnIndexChanged(weapon)
		NewWeaponSelecter.alpha = 1
		NewWeaponSelecter.fadeTime = CurTime() + 5
		NewWeaponSelecter.markup = nil

		if (IsValid(weapon)) then
			local instructions = weapon.Instructions
			local text = ""

			local source, pitch = hook.Run("WeaponCycleSound")
			LocalPlayer():EmitSound(source or "common/talk.wav", 50, pitch or 180)
		end
	end

	hook.Add( "PlayerBindPress", "NewWeaponSelecter_PlayerBindPress", function(ply, bind, pressed)
		if (not IsEnabled()) then return end
		bind = bind:lower()

		if (!pressed or !bind:find("invprev") and !bind:find("invnext")
		and !bind:find("slot") and !bind:find("attack")) then
			return
		end

		local currentWeapon = ply:GetActiveWeapon()
		local bValid = IsValid(currentWeapon)
		local bTool

		if (ply:InVehicle() or (bValid and currentWeapon:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK))) then
			return
		end

		if (bValid and currentWeapon:GetClass() == "gmod_tool") then
			local tool = ply:GetTool()
			bTool = tool and (tool.Scroll != nil)
		end

		NewWeaponSelecter.weapons = {}

		for _, v in pairs(ply:GetWeapons()) do
			NewWeaponSelecter.weapons[#NewWeaponSelecter.weapons + 1] = v
		end

		if (bind:find("invprev") and !bTool) then
			local oldIndex = NewWeaponSelecter.index
			NewWeaponSelecter.index = math.min(NewWeaponSelecter.index + 1, #NewWeaponSelecter.weapons)

			if (NewWeaponSelecter.alpha == 0 or oldIndex != NewWeaponSelecter.index) then
				OnIndexChanged(NewWeaponSelecter.weapons[NewWeaponSelecter.index])
			end

			return true
		elseif (bind:find("invnext") and !bTool) then
			local oldIndex = NewWeaponSelecter.index
			NewWeaponSelecter.index = math.max(NewWeaponSelecter.index - 1, 1)

			if (NewWeaponSelecter.alpha == 0 or oldIndex != NewWeaponSelecter.index) then
				OnIndexChanged(NewWeaponSelecter.weapons[NewWeaponSelecter.index])
			end

			return true
		elseif (bind:find("slot")) then
			NewWeaponSelecter.index = math.Clamp(tonumber(bind:match("slot(%d)")) or 1, 1, #NewWeaponSelecter.weapons)
			OnIndexChanged(NewWeaponSelecter.weapons[NewWeaponSelecter.index])

			return true
		elseif (bind:find("attack") and NewWeaponSelecter.alpha > 0) then
			local weapon = NewWeaponSelecter.weapons[NewWeaponSelecter.index]

			if (IsValid(weapon)) then
				LocalPlayer():EmitSound("HL2Player.Use")

				input.SelectWeapon(weapon)
				NewWeaponSelecter.alpha = 0
			end

			return true
		end
	end)

	hook.Add( "Think", "NewWeaponSelecter_Think", function()
		local ply = LocalPlayer()
		if (!IsValid(ply) or !ply:Alive()) then
			NewWeaponSelecter.alpha = 0
		end
	end)

	hook.Add( "ScoreboardShow", "NewWeaponSelecter_ScoreboardShow", function()
		NewWeaponSelecter.alpha = 0
	end)
--end
