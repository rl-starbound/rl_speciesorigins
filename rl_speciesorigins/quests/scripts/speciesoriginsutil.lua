require("/quests/scripts/questutil.lua")
require "/scripts/util.lua"

speciesoriginsutil = {}

function speciesoriginsutil.uniqueEntityTracker(uniqueId)
  return function()
    local promise = world.findUniqueEntity(uniqueId)
    while not promise:finished() do
      coroutine.yield()
    end
    if promise:succeeded() then
      return promise:result()
    end
    sb.logError("world.findUniqueEntity failed: " .. uniqueId)
    return nil
  end
end

function speciesoriginsutil.pointToUniqueEntity(uniqueId, interval, loopCond)
  return function()
    local locationTracker = speciesoriginsutil.uniqueEntityTracker(uniqueId)
    while loopCond() do
      local location = locationTracker()
      if location ~= nil then
        questutil.pointCompassAt(location)
      end
      util.wait(interval)
    end
    questutil.pointCompassAt(nil)
  end
end

function speciesoriginsutil.addCoroutine(coroutines, name, fn, ...)
  coroutines[name] = coroutine.create(fn)
  coroutine.resume(fn, ...)
end

function speciesoriginsutil.delCoroutine(coroutines, name)
  coroutines[name] = nil
end

function speciesoriginsutil.updateCoroutines(coroutines)
  for name, fn in pairs(coroutines) do
    s, r = coroutine.resume(fn)
    if not s then error(r) end
    if coroutine.status(fn) == "dead" then
      speciesoriginsutil.delCoroutine(coroutines, name)
    end
  end
end
