--[[
  SWITXT - Switch Text Widget
  Version 1.2

  Designed for:
    RadioMaster TX16S MK3
    EdgeTX 2.12.x

  Three independent switch-position -> text assignments.

  Each assignment has:
    Switch position
    Text
    Text color

  Example:

    SD↑  -> ARMED       -> Green
    SD↓  -> DISARMED    -> Red
    SF↓  -> MOTOR OFF   -> Yellow

  The widget automatically centers the text horizontally
  and vertically within the widget area.
]]

local NAME = "SWITXT"

----------------------------------------------------------------
-- Widget options
--
-- 3 assignments x 3 options = 9 options
--
-- This remains within the EdgeTX maximum of 10 widget options.
----------------------------------------------------------------

local options = {
  { "Switch1", SWITCH, 0 },
  { "Text1",   STRING, "ARMED" },
  { "Color1",  COLOR,  GREEN },

  { "Switch2", SWITCH, 0 },
  { "Text2",   STRING, "DISARMED" },
  { "Color2",  COLOR,  RED },

  { "Switch3", SWITCH, 0 },
  { "Text3",   STRING, "MOTOR OFF" },
  { "Color3",  COLOR,  YELLOW },
}

----------------------------------------------------------------
-- Create
----------------------------------------------------------------

local function create(zone, opts)

  local widget = {
    zone = zone,
    options = opts
  }

  return widget
end

----------------------------------------------------------------
-- Update
----------------------------------------------------------------

local function update(widget, opts)

  widget.options = opts

end

----------------------------------------------------------------
-- Find active assignment
----------------------------------------------------------------

local function getActiveAssignment(widget)

  local opts = widget.options

  --------------------------------------------------------------
  -- Assignment 1
  --------------------------------------------------------------

  if opts.Switch1 and opts.Switch1 ~= 0 then

    if getSwitchValue(opts.Switch1) then

      return opts.Text1 or "", opts.Color1

    end

  end

  --------------------------------------------------------------
  -- Assignment 2
  --------------------------------------------------------------

  if opts.Switch2 and opts.Switch2 ~= 0 then

    if getSwitchValue(opts.Switch2) then

      return opts.Text2 or "", opts.Color2

    end

  end

  --------------------------------------------------------------
  -- Assignment 3
  --------------------------------------------------------------

  if opts.Switch3 and opts.Switch3 ~= 0 then

    if getSwitchValue(opts.Switch3) then

      return opts.Text3 or "", opts.Color3

    end

  end

  --------------------------------------------------------------
  -- Nothing matched
  --------------------------------------------------------------

  return "", nil

end

----------------------------------------------------------------
-- Refresh
----------------------------------------------------------------

local function refresh(widget)

  local zone = widget.zone

  --------------------------------------------------------------
  -- Find active text
  --------------------------------------------------------------

  local text, color = getActiveAssignment(widget)

  --------------------------------------------------------------
  -- Nothing to display
  --------------------------------------------------------------

  if text == "" then
    return
  end

  --------------------------------------------------------------
  -- Calculate center of widget
  --------------------------------------------------------------

  local centerX = zone.x + (zone.w / 2)
  local centerY = zone.y + (zone.h / 2)

  --------------------------------------------------------------
  -- Display text
  --
  -- MIDSIZE is used as a sensible default for the TX16S MK3.
  --
  -- CENTER makes the text horizontally centered.
  -- VCENTER makes it vertically centered.
  --------------------------------------------------------------

  lcd.drawText(
    centerX,
    centerY,
    text,
    MIDSIZE + CENTER + VCENTER + color
  )

end

----------------------------------------------------------------
-- Background
----------------------------------------------------------------

local function background(widget)

  -- Nothing required.
  --
  -- The widget only needs to update while visible.

end

----------------------------------------------------------------
-- Widget interface
----------------------------------------------------------------

return {
  name = NAME,
  options = options,

  create = create,
  update = update,
  refresh = refresh,
  background = background
}
