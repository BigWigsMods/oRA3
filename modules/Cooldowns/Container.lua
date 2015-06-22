
local _, scope = ...
local oRA3 = scope.addon
local L = scope.locale
local oRA3CD = oRA3:GetModule("Cooldowns")

-- GLOBALS: GameFontNormal UIParent

---------------------------------------
-- Display

local container = {}

function container:Lock()
	if not self.db.showDisplay then return end
	if not self.frame then self:Setup() end
	local frame = self.frame
	frame:EnableMouse(false)
	frame:SetMovable(false)
	frame:SetResizable(false)
	frame:RegisterForDrag()
	frame.drag:Hide()
	frame.header:Hide()
	frame.bg:SetTexture(0, 0, 0, 0)
	self.db.lockDisplay = true
	if self.OnLock then
		self:OnLock()
	end
end

function container:Unlock()
	if not self.db.showDisplay then return end
	if not self.frame then self:Setup() end
	local frame = self.frame
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:RegisterForDrag("LeftButton")
	frame.bg:SetTexture(0, 0, 0, 0.3)
	frame.drag:Show()
	frame.header:Show()
	self.db.lockDisplay = false
	if self.OnUnlock then
		self:OnUnlock()
	end
end

function container:Show()
	if not self.db.showDisplay then return end
	if not self.frame then self:Setup() end
	self.frame:Show()
	if self.OnShow then
		self:OnShow()
	end
end

function container:Hide()
	if not self.frame then return end
	self.frame:Hide()
	if self.OnHide then
		self:OnHide()
	end
end

do
	local function onDragHandleMouseDown(self) self:GetParent():StartSizing("BOTTOMRIGHT") end
	local function onDragHandleMouseUp(self) self:GetParent():StopMovingOrSizing() end
	local function onDragStop(self)
		self:StopMovingOrSizing()
		oRA3:SavePosition(self:GetName())
	end
	local function onResize(self, width, height)
		oRA3:SavePosition(self:GetName())
		local display = self.display
		if display.OnResize then
			display:OnResize(width, height)
		end
	end
	local function onMouseDown(self, button, down)
		if button == "RightButton" then
			oRA3CD:OpenDisplayOptions(self.display)
		end
	end

	function container:Setup()
		if self.frame then
			if self.db.showDisplay then
				self:Show()
			end
			return
		end

		local frameName = "oRA3CooldownFrame"..self.type..self.name
		local frame = _G[frameName] -- reclaim the frame if the display was deleted
		if not frame then
			frame = CreateFrame("Frame", frameName, UIParent)
			frame:SetFrameStrata("BACKGROUND")
			frame:SetMinResize(100, 20)
			frame:SetWidth(200)
			frame:SetHeight(148)

			local bg = frame:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints(frame)
			bg:SetBlendMode("BLEND")
			bg:SetTexture(0, 0, 0, 0.3)
			frame.bg = bg

			local header = frame:CreateFontString(nil, "OVERLAY")
			header:SetFontObject(GameFontNormal)
			header:SetText(("Cooldowns: %s"):format(self.name))
			header:SetPoint("BOTTOM", frame, "TOP", 0, 4)
			frame.header = header

			local help = frame:CreateFontString(nil, "HIGHLIGHT")
			help:SetFontObject(GameFontNormal)
			help:SetText(L.rightClick)
			--help:SetAllPoints(frame)
			help:SetWordWrap(true)
			help:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -2, -4)
			help:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 2, -4)

			local drag = CreateFrame("Frame", frameName.."DragHandle", frame)
			drag:SetFrameLevel(frame:GetFrameLevel() + 10) -- place this above everything
			drag:SetSize(16, 16)
			drag:SetAlpha(0.5)
			drag:SetPoint("BOTTOMRIGHT", frame, -1, 1)
			drag:EnableMouse(true)
			drag:SetScript("OnMouseDown", onDragHandleMouseDown)
			drag:SetScript("OnMouseUp", onDragHandleMouseUp)
			frame.drag = drag

			local texture = drag:CreateTexture(nil, "OVERLAY")
			texture:SetTexture("Interface\\AddOns\\oRA3\\images\\draghandle")
			texture:SetSize(16, 16)
			texture:SetBlendMode("ADD")
			texture:SetPoint("CENTER", drag)

			frame:SetScript("OnSizeChanged", onResize)
			frame:SetScript("OnDragStart", frame.StartMoving)
			frame:SetScript("OnDragStop", onDragStop)
			frame:SetScript("OnMouseDown", onMouseDown)
		end
		self.frame = frame
		frame.display = self

		if self.OnSetup then
			self:OnSetup(frame)
		end

		oRA3:RestorePosition(frameName)

		if self.db.lockDisplay then
			self:Lock()
		else
			self:Unlock()
		end
		if self.db.showDisplay then
			self:Show()
		else
			self:Hide()
		end
	end
end

function container:Delete()
	if self.OnDelete then
		self:OnDelete()
	end
	self.frame = nil
	oRA3.db.profile.positions["oRA3CooldownFrame"..self.type..self.name] = nil
end


function container:GetContainer()
	-- this is a bit weird. for all intents and purposes "self" is the container
	-- ...except when you need to setpoint it. oh well
	return self.frame
end

function container:GetPosition()
	local opt = oRA3.db.profile.positions["oRA3CooldownFrame"..self.type..self.name]
	if opt then
		return opt.PosX, opt.PosY, opt.Width, opt.Height
	end
end

function container:SetPosition(x, y, w, h)
	if not x or not y then return end

	local name = "oRA3CooldownFrame"..self.type..self.name
	local opt = oRA3.db.profile.positions[name]
	if not opt then
		oRA3.db.profile.positions[name] = {}
		opt = oRA3.db.profile.positions[name]
	end

	opt.PosX = x
	opt.PosY = y
	if w then opt.Width = w end
	if h then opt.Height = h end

	if not self.frame then
		self:Setup()
	end

	return oRA3:RestorePosition(name)
end

-- add come convenience methods
do
	local frame_methods = {
		"IsShown", "GetWidth", "GetHeight", "GetSize",
		"GetTop", "GetBottom", "GetLeft", "GetRight"
	}

	for _, name in next, frame_methods do
		container[name] = function(self)
			local frame = self.frame
			return frame and frame[name](frame)
		end
	end
end

---------------------------------------
-- API

function oRA3CD:AddContainer(display)
	display.frame = nil

	for k, v in next, container do
		display[k] = v
	end
end
