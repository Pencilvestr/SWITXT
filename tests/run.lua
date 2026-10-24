-- Run from the repository root: lua tests/run.lua
-- API stubs exercise logic/layout; these are not radio/simulator acceptance tests.
local readFile = ... -- Optional file reader for embedded Lua test runtimes.
local passed = 0
local function test(name, body)
  local ok, err = pcall(body)
  if not ok then error(name .. ": " .. tostring(err), 0) end
  passed = passed + 1
  print("ok " .. passed .. " - " .. name)
end

local function equal(actual, expected)
  assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end

local function read(path)
  if readFile then return readFile(path) end
  local file = assert(io.open(path, "r"))
  local source = file:read("*a")
  file:close()
  return source
end

local colorSource = read("main.lua")
local monoSource = read("mono/switxt.lua")
local dimensions = {
  [0] = { 12, 24 }, [128] = { 6, 12 }, [256] = { 8, 16 }, [512] = { 16, 32 },
  [768] = { 24, 48 }, [1024] = { 36, 64 },
}

local function colorEnvironment()
  local env = setmetatable({
    SWITCH = 1, STRING = 2, COLOR = 3,
    GREEN = 65536, RED = 131072, YELLOW = 196608,
    CENTER = 8, TINSIZE = 128, SMLSIZE = 256, MIDSIZE = 512, DBLSIZE = 768, XXLSIZE = 1024,
    LCD_W = 480, LCD_H = 272,
  }, { __index = _G })
  local calls, states = {}, {}
  local metrics = { measures = 0, clears = 0 }
  env.getSwitchValue = function(id) return states[id] end
  env.lcd = {
    sizeText = function(text, font)
      metrics.measures = metrics.measures + 1
      local dim = assert(dimensions[font], "unknown font")
      return #text * dim[1], dim[2]
    end,
    drawText = function(x, y, text, flags)
      assert(x == math.floor(x) and y == math.floor(y), "noninteger coordinates")
      calls[#calls + 1] = { x = x, y = y, text = text, flags = flags }
    end,
    clear = function() metrics.clears = metrics.clears + 1 end,
  }
  local definition = assert(load(colorSource, "main.lua", "t", env))()
  return definition, calls, states, metrics, env
end

test("existing option names, order and defaults survive upgrades", function()
  local definition = colorEnvironment()
  local expected = {
    {"Switch1", 1, 0}, {"Text1", 2, "ARMED"}, {"Color1", 3, 65536},
    {"Switch2", 1, 0}, {"Text2", 2, "DISARMED"}, {"Color2", 3, 131072},
    {"Switch3", 1, 0}, {"Text3", 2, "MOTOR OFF"}, {"Color3", 3, 196608},
  }
  equal(#definition.options, #expected)
  for i = 1, #expected do
    for j = 1, 3 do equal(definition.options[i][j], expected[i][j]) end
  end
end)

test("unassigned, invalid and inactive switches draw nothing", function()
  local def, calls, states = colorEnvironment()
  states[0] = true
  local w = def.create({x=0,y=0,w=200,h=100}, nil)
  def.refresh(w)
  def.update(w, {Switch1=0,Text1="ARMED",Switch2=99,Text2="UNKNOWN",Switch3="bad"})
  def.refresh(w)
  equal(#calls, 0)
end)

test("first active assignment wins, including empty labels", function()
  local def, calls, states = colorEnvironment()
  states[1], states[2], states[3] = true, true, true
  local w = def.create({x=0,y=0,w=300,h=100}, {
    Switch1=1,Text1="ARMED",Switch2=2,Text2="DISARMED",Switch3=3,Text3="MOTOR OFF",
  })
  def.refresh(w)
  equal(calls[1].text, "ARMED")
  w.options.Text1 = ""
  def.refresh(w)
  equal(#calls, 1)
  states[1] = false
  def.refresh(w)
  equal(calls[2].text, "DISARMED")
  states[2] = false
  def.refresh(w)
  equal(calls[3].text, "MOTOR OFF")
end)

test("negative switch IDs and color zero remain valid", function()
  local def, calls, states = colorEnvironment()
  states[-2] = true
  local w = def.create({x=0,y=0,w=300,h=100}, {Switch1=-2,Text1="ACTIVE",Color1=0})
  def.refresh(w)
  assert(calls[1].flags < 65536, "zero color replaced by default color")
  w.options.Color1 = nil
  def.refresh(w)
  assert(calls[2].flags >= 65536, "missing color did not use default")
end)

test("portrait, landscape, high resolution and offset zones fit", function()
  local def, calls, states = colorEnvironment()
  states[1] = true
  for _, zone in ipairs({
    {x=0,y=0,w=480,h=272}, {x=0,y=0,w=480,h=320},
    {x=0,y=0,w=320,h=480}, {x=0,y=0,w=800,h=480},
    {x=19,y=31,w=80,h=40}, {x=0,y=0,w=40,h=24},
  }) do
    def.refresh(def.create(zone, {Switch1=1,Text1="MOTOR OFF"}))
    local call = calls[#calls]
    local font = call.flags % 65536 - 8
    local dim = dimensions[font]
    assert(#call.text * dim[1] <= zone.w - 4)
    assert(dim[2] <= zone.h - 4)
    equal(call.x, math.floor(zone.x + zone.w / 2))
    equal(call.y, math.floor(zone.y + (zone.h - dim[2]) / 2))
  end
end)

test("full-screen uses LCD dimensions, and returning restores zone", function()
  local def, calls, states, metrics, env = colorEnvironment()
  env.LCD_W, env.LCD_H = 800, 480
  states[1] = true
  local w = def.create({x=0,y=0,w=80,h=40}, {Switch1=1,Text1="ARMED"})
  def.refresh(w, 0)
  equal(calls[1].x, 400)
  equal(metrics.clears, 1)
  def.refresh(w)
  equal(calls[2].x, 40)
  equal(metrics.clears, 1)
end)

test("full-screen is cleared when the active switch turns off", function()
  local def, calls, states, metrics = colorEnvironment()
  states[1] = true
  local w = def.create({x=0,y=0,w=80,h=40}, {Switch1=1,Text1="ARMED"})
  def.refresh(w, 0)
  states[1] = false
  def.refresh(w, 0)
  equal(#calls, 1)
  equal(metrics.clears, 2)
end)

test("layout cache is per instance and invalidates on resize/update", function()
  local def, calls, states, metrics = colorEnvironment()
  states[1] = true
  local a = def.create({x=0,y=0,w=300,h=100}, {Switch1=1,Text1="ARMED"})
  local b = def.create({x=0,y=0,w=100,h=40}, {Switch1=1,Text1="ARMED"})
  def.refresh(a)
  local before = metrics.measures
  def.refresh(a)
  equal(metrics.measures, before)
  def.refresh(b)
  assert(metrics.measures > before)
  before = metrics.measures
  a.zone.w = 100
  def.refresh(a)
  assert(metrics.measures > before)
  def.update(a, {Switch1=1,Text1="NEW"})
  def.refresh(a)
  equal(calls[#calls].text, "NEW")
end)

test("oversize UTF-8 labels truncate at complete characters", function()
  local def, calls, states = colorEnvironment()
  states[1] = true
  def.refresh(def.create({x=0,y=0,w=80,h=24}, {Switch1=1,Text1="éééééééééé"}))
  local text = calls[1].text
  equal(string.sub(text, -3), "...")
  equal((string.gsub(text, "é", "")), "...")
end)

test("tiny or empty zones do not spill text", function()
  local def, calls, states = colorEnvironment()
  states[1] = true
  for _, size in ipairs({0, 1, 8, 16}) do
    def.refresh(def.create({x=0,y=0,w=size,h=size}, {Switch1=1,Text1="ARMED"}))
  end
  equal(#calls, 0)
end)

local function monoEnvironment(width, source, indices)
  local env = setmetatable({ LCD_W=width, LCD_H=64, DBLSIZE=512, SMLSIZE=256, CENTER=32 }, {__index=_G})
  local calls, states, metrics = {}, {}, {clears=0}
  indices = indices or {L01=101,L02=102,L03=103}
  env.getSwitchIndex = function(name) return indices[name] end
  env.getSwitchValue = function(id) return states[id] end
  env.lcd = {
    clear = function() metrics.clears = metrics.clears + 1 end,
    drawText = function(x,y,text,flags)
      calls[#calls + 1] = {x=x,y=y,text=text,flags=flags}
    end,
  }
  local def = assert(load(source or monoSource, "mono/switxt.lua", "t", env))()
  return def, calls, states, metrics
end

for _, width in ipairs({128,212}) do
  test("monochrome " .. width .. "px uses only its own LCD API", function()
    local def, calls, states, metrics = monoEnvironment(width)
    states[101],states[102],states[103] = true,true,true
    def.init()
    equal(def.run(0), 0)
    equal(calls[1].text, "ARMED")
    equal(calls[1].x, width / 2)
    states[101] = false
    def.run(0)
    equal(calls[2].text, "DISARMED")
    states[102] = false
    def.run(0)
    equal(calls[3].text, "MOTOR OFF")
    states[103] = false
    def.run(0)
    equal(#calls, 3)
    equal(metrics.clears, 4)
  end)
end

test("unknown switch names report a configuration error", function()
  local def, calls, states = monoEnvironment(128, nil, {L01=101,L03=103})
  states[101] = true
  def.run(0)
  equal(calls[2].text, "Check switch names")
end)

test("monochrome long labels shrink and visibly truncate", function()
  local source = string.gsub(monoSource, 'text = "ARMED"', 'text = "A VERY LONG CUSTOM STATUS LABEL"', 1)
  local def, calls, states = monoEnvironment(128, source)
  states[101] = true
  def.run(0)
  equal(string.sub(calls[1].text, -3), "...")
  assert(#calls[1].text * 5 <= 124)
  equal(calls[1].flags, 256 + 32)
end)

test("monochrome punctuation avoids limited large-font characters", function()
  local source = string.gsub(monoSource, 'text = "ARMED"', 'text = "ARMED?"', 1)
  local def, calls, states = monoEnvironment(128, source)
  states[101] = true
  def.run(0)
  equal(calls[1].text, "ARMED?")
  equal(calls[1].flags, 32)
end)

test("monochrome disabled entries are skipped and inverted IDs work", function()
  local source = string.gsub(monoSource, 'switch = "L01"', 'switch = ""', 1)
  local def, calls, states = monoEnvironment(128, source, {L02=-102,L03=103})
  states[-102] = true
  def.run(0)
  equal(calls[1].text, "DISARMED")
end)

test("monochrome UTF-8 truncation preserves complete characters", function()
  local source = string.gsub(monoSource, 'text = "ARMED"', 'text = "' .. string.rep("é", 30) .. '"', 1)
  local def, calls, states = monoEnvironment(128, source)
  states[101] = true
  def.run(0)
  local text = calls[1].text
  equal((string.gsub(text, "é", "")), "...")
  assert(#text * 5 <= 124)
end)

print("Passed " .. passed .. " tests")
