-- Test-only observer: production scripts are copied unchanged beside this file.
local color = LCD_H > 64
local app = loadScript(color and '/WIDGETS/SWITXT/main.lua' or '/SCRIPTS/TELEMETRY/switxt.lua')()
local phase, changed, lastRead, reported = nil, 0, -100, false
local on = assert(getSwitchIndex('ON'), 'ON switch unavailable')
local ids = {getSwitchIndex('L01'),getSwitchIndex('L02'),getSwitchIndex('L03')}
local originalOptions

local function readPhase()
  local now = getTime()
  if now - lastRead < 25 then return end
  lastRead = now
  local nextPhase = assert(loadScript('/phase.lua','t'))()
  if phase and phase.id == nextPhase.id then return end
  phase, changed, reported = nextPhase, now, false
  for i = 1, 3 do
    model.setLogicalSwitch(i-1, {func=LS_FUNC_AND,v1=phase.states[i] and on or -on,v2=on})
  end
end

local function create(zone, options)
  originalOptions = options
  print('NATIVE_DEFAULTS|'..options.Text1..'|'..options.Text2..'|'..options.Text3)
  return { zone=zone }
end

local function render(widget,event)
  readPhase()
  if not phase then return end
  local now = getTime()
  local real = lcd
  local drawn, fits = '', true
  local zone = color and widget.zone or {x=0,y=0,w=LCD_W,h=LCD_H}
  if phase.small then zone={x=12,y=12,w=80,h=40} end
  if color then
    local opts={Switch1=ids[1],Text1=phase.long and 'A VERY LONG STATUS LABEL' or originalOptions.Text1,Color1=originalOptions.Color1,
      Switch2=ids[2],Text2=originalOptions.Text2,Color2=originalOptions.Color2,
      Switch3=ids[3],Text3=originalOptions.Text3,Color3=originalOptions.Color3}
    if not widget.app or widget.phase ~= phase.id then
      widget.app=app.create(zone,opts)
      widget.phase=phase.id
    end
    widget.app.zone=zone
  end
  lcd=setmetatable({drawText=function(x,y,text,flags)
    drawn=text
    real.drawText(x,y,text,flags)
    if color then
      local width,height=real.sizeText(text,flags)
      local area=event~=nil and {x=0,y=0,w=LCD_W,h=LCD_H} or zone
      fits = fits and x-width/2>=area.x and x+width/2<=area.x+area.w and y>=area.y and y+height<=area.y+area.h
    end
  end},{__index=real})
  local ok,err=pcall(function()
    if color then app.refresh(widget.app,event) else app.run(event) end
  end)
  lcd=real
  assert(ok,err)
  if now-changed>=40 and not reported then
    reported=true
    print('CHECK|'..phase.id..'|'..drawn..'|'..tostring(fits)..'|'..tostring(event~=nil)..'|'..getVersion()..'|'..
      tostring(getSwitchValue(ids[1]))..','..tostring(getSwitchValue(ids[2]))..','..tostring(getSwitchValue(ids[3])))
  end
end

if color then
  return {name='LabTest',options=app.options,create=create,update=function() end,refresh=render}
end
return {init=app.init,run=function(event) render(nil,event); return 0 end}
