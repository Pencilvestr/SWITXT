-- SWITXT 1.3 - color-screen widget for EdgeTX 2.11 and later.
-- Install as /WIDGETS/SWITXT/main.lua. Monochrome radios use mono/switxt.lua.

-- Keep the option names and order stable so existing model settings survive.
local options = {
  { "Switch1", SWITCH, 0 },
  { "Text1", STRING, "ARMED" },
  { "Color1", COLOR, GREEN },
  { "Switch2", SWITCH, 0 },
  { "Text2", STRING, "DISARMED" },
  { "Color2", COLOR, RED },
  { "Switch3", SWITCH, 0 },
  { "Text3", STRING, "MOTOR OFF" },
  { "Color3", COLOR, YELLOW },
}

local assignments = {
  { switch = "Switch1", text = "Text1", color = "Color1", defaultColor = GREEN },
  { switch = "Switch2", text = "Text2", color = "Color2", defaultColor = RED },
  { switch = "Switch3", text = "Text3", color = "Color3", defaultColor = YELLOW },
}

-- These are EdgeTX font flags, not radio-specific pixel sizes.
local fonts = { XXLSIZE, DBLSIZE, MIDSIZE, 0, SMLSIZE, TINSIZE }

local function create(zone, opts)
  return { zone = zone, options = opts or {} }
end

local function update(widget, opts)
  widget.options = opts or {}
  widget.layout = nil
end

local function activeAssignment(opts)
  for i = 1, #assignments do
    local assignment = assignments[i]
    local switch = opts[assignment.switch]
    if type(switch) == "number" and switch ~= 0 and getSwitchValue(switch) then
      local text = opts[assignment.text]
      local color = opts[assignment.color]
      if type(text) ~= "string" then text = "" end
      if type(color) ~= "number" then color = assignment.defaultColor end
      -- An empty active label still takes priority, matching earlier versions.
      return text, color
    end
  end
  return "", nil
end

-- Remove a whole UTF-8 character, rather than leaving a partial byte sequence.
local function removeLastCharacter(text)
  local last = #text
  while last > 1 do
    local byte = string.byte(text, last)
    if byte < 128 or byte >= 192 then break end
    last = last - 1
  end
  return string.sub(text, 1, last - 1)
end

local function fitText(text, width, height)
  local availableWidth = math.max(0, width - 4)
  local availableHeight = math.max(0, height - 4)
  for i = 1, #fonts do
    local font = fonts[i]
    local w, h = lcd.sizeText(text, font)
    if w <= availableWidth and h <= availableHeight then
      return { text = text, font = font, height = h }
    end
  end

  -- If even the smallest font cannot fit, make truncation visible.
  local suffix = "..."
  local w, h = lcd.sizeText(suffix, TINSIZE)
  if w > availableWidth or h > availableHeight then
    return { text = "", font = TINSIZE, height = h }
  end
  local shortened = text
  repeat
    shortened = removeLastCharacter(shortened)
    w = lcd.sizeText(shortened .. suffix, TINSIZE)
  until w <= availableWidth
  return { text = shortened .. suffix, font = TINSIZE, height = h }
end

local function refresh(widget, event)
  local zone = widget.zone
  local x, y, width, height = zone.x, zone.y, zone.w, zone.h
  if event ~= nil then
    -- EdgeTX supplies an event (including 0) only in full-screen mode.
    x, y, width, height = 0, 0, LCD_W, LCD_H
    lcd.clear()
  end
  if width <= 0 or height <= 0 then return end

  local text, color = activeAssignment(widget.options)
  if text == "" then return end

  -- Cache measurements per instance, but read zone dimensions on every refresh.
  local layout = widget.layout
  if not layout or layout.source ~= text or layout.width ~= width or layout.zoneHeight ~= height then
    layout = fitText(text, width, height)
    layout.source, layout.width, layout.zoneHeight = text, width, height
    widget.layout = layout
  end
  if layout.text == "" then return end

  lcd.drawText(
    math.floor(x + width / 2),
    math.floor(y + (height - layout.height) / 2),
    layout.text,
    layout.font + CENTER + color
  )
end

return {
  name = "SWITXT",
  options = options,
  create = create,
  update = update,
  refresh = refresh,
}
