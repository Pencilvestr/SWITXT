-- SWITXT 1.3 - monochrome telemetry screen for EdgeTX 2.11 and later.
-- Install as /SCRIPTS/TELEMETRY/switxt.lua, then select it as a Script screen.

-- Configure L01/L02/L03 on each model to activate the corresponding label.
-- Edit the labels here. Use "" for a switch to disable that assignment.
-- Switch names are resolved by EdgeTX; do not copy numeric IDs from another radio.
local assignments = {
  { switch = "L01", text = "ARMED" },
  { switch = "L02", text = "DISARMED" },
  { switch = "L03", text = "MOTOR OFF" },
}

local initialized = false
local configurationError = false
local cachedText, cachedWidth, cachedFont, cachedHeight, cachedDisplayText

local function init()
  configurationError = false
  for i = 1, #assignments do
    local assignment = assignments[i]
    assignment.id = nil
    if assignment.switch ~= "" then
      assignment.id = getSwitchIndex(assignment.switch)
      if not assignment.id or assignment.id == 0 then
        configurationError = true
      end
    end
  end
  cachedText = nil
  initialized = true
end

local function activeText()
  for i = 1, #assignments do
    local assignment = assignments[i]
    if assignment.id and getSwitchValue(assignment.id) then
      return assignment.text
    end
  end
  return ""
end

local function removeLastCharacter(text)
  local last = #text
  while last > 1 do
    local byte = string.byte(text, last)
    if byte < 128 or byte >= 192 then break end
    last = last - 1
  end
  return string.sub(text, 1, last - 1)
end

local function fitText(text, width)
  -- Monochrome LCD APIs have no lcd.sizeText. Use conservative glyph widths
  -- to choose a font, then let CENTER align the proportional text precisely.
  -- DBLSIZE has a limited character set: use normal fonts for other symbols.
  local simpleText = not string.find(text, "[^A-Za-z0-9 ,./:_%-]")
  if simpleText and #text * 11 <= width - 4 then
    return text, DBLSIZE, 16
  end
  if #text * 6 <= width - 4 then return text, 0, 8 end
  if #text * 5 <= width - 4 then return text, SMLSIZE, 6 end

  local shortened = text
  repeat
    shortened = removeLastCharacter(shortened)
  until (#shortened + 3) * 5 <= width - 4
  return shortened .. "...", SMLSIZE, 6
end

local function run(event)
  if not initialized then init() end
  -- Telemetry scripts own their screen; clear it even when no switch matches.
  lcd.clear()
  if configurationError then
    lcd.drawText(2, 2, "SWITXT", 0)
    lcd.drawText(2, 16, "Check switch names", SMLSIZE)
    return 0
  end

  local text = activeText()
  if text == "" then return 0 end
  if cachedText ~= text or cachedWidth ~= LCD_W then
    cachedDisplayText, cachedFont, cachedHeight = fitText(text, LCD_W)
    cachedText, cachedWidth = text, LCD_W
  end
  lcd.drawText(
    math.floor(LCD_W / 2),
    math.floor((LCD_H - cachedHeight) / 2),
    cachedDisplayText,
    cachedFont + CENTER
  )
  return 0
end

return { init = init, run = run }
