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
		if (name == "CHudWeaponSelection") then
			return false
		end
	end)

	hook.Add( "HUDPaint", "NewWeaponSelecter_HUDPaint", function()
		local frameTime = FrameTime()

		NewWeaponSelecter.alphaDelta = Lerp(frameTime * 10, NewWeaponSelecter.alphaDelta, NewWeaponSelecter.alpha)

		local fraction = NewWeaponSelecter.alphaDelta

		if (fraction > 0.01) then
			local x, y = 100, ScrH() * 0.4
			local spacing = math.pi * 0.6
			local radius = 240 * NewWeaponSelecter.alphaDelta
			local shiftX = ScrW() * .02

			NewWeaponSelecter.deltaIndex = Lerp(frameTime * 12, NewWeaponSelecter.deltaIndex, NewWeaponSelecter.index)

			local index = NewWeaponSelecter.deltaIndex

			if (!NewWeaponSelecter.weapons[NewWeaponSelecter.index]) then
				NewWeaponSelecter.index = #NewWeaponSelecter.weapons
			end

			for i = 1, #NewWeaponSelecter.weapons do
				local theta = (i - index) * 0.1

				local color2 = ColorAlpha(
					i == NewWeaponSelecter.index and Color(155, 20, 121, 100) or Color(100, 100, 100, 100),
					(150 - math.abs(theta * 3) * 150) * fraction
				)

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
					y + lastY + math.sin(theta * spacing + math.pi) * radius - ty / 2 ,
					1))
				matrix:Scale(Vector(1, 1, 0) * scale)

				cam.PushModelMatrix(matrix)
					NewDrawText(weaponName, ebatTextKruto, ty / 2 - 1, color3, 0, 1, "NewWeaponSelectFont")
					if i > NewWeaponSelecter.index - 4 and i < NewWeaponSelecter.index + 4 then
					surface.SetTexture(surface.GetTextureID("vgui/gradient-l"))
					surface.SetDrawColor(color2)
					surface.DrawTexturedRect(0, 0, 400, 32)
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
