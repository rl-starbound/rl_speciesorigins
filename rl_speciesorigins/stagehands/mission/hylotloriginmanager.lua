require "/scripts/rect.lua"

function init()
  self.containsPlayers = {}
  self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
  self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())

  message.setHandler("activateBeamaxe", function(...)
      local beamaxeSearchArea = rect.translate({180, -170, 220, -150}, entity.position())
      world.objectQuery(rect.ll(beamaxeSearchArea), rect.ur(beamaxeSearchArea), {callScript = "showBeamaxe"})
    end)

  message.setHandler("midpointSwitch", function(...)
      local npcSearchArea = rect.translate({-200, -20, 50, 20}, entity.position())
      world.npcQuery(rect.ll(npcSearchArea), rect.ur(npcSearchArea), {callScript = "status.setResource", callScriptArgs = {"health", 0}})
      world.setSkyTime(config.getParameter("badTime"))
      world.setProperty("nonCombat", false)
    end)

  message.setHandler("openMineHatch", function(...)
      local doorSearchArea = rect.translate({295, -35, 305, -25}, entity.position())
      world.objectQuery(rect.ll(doorSearchArea), rect.ur(doorSearchArea), {callScript = "openDoor"})
    end)

  message.setHandler("overrunBarricade", function(...)
      local npcSearchArea = rect.translate({145, -170, 200, -140}, entity.position())
      world.npcQuery(rect.ll(npcSearchArea), rect.ur(npcSearchArea), {callScript = "status.setResource", callScriptArgs = {"health", 0}})
      world.spawnNpc({575, 701}, "floran", "shroomguard", 1)
      world.spawnNpc({580, 701}, "floran", "shroomguard", 1)
      world.spawnNpc({590, 702}, "floran", "shroomguard", 1)
    end)

  message.setHandler("setSpecies", function(_, _, species) self.species = species end)

  world.setSkyTime(config.getParameter("goodTime"))

  self.hasUpdatedShip = false
end

function update(dt)
  world.loadRegion(self.signalRegion)
  queryPlayers()

  if self.species and not self.hasUpdatedShip then
    local shipSearchArea = rect.translate({500, -50, 600, 50}, entity.position())
    local ships = world.objectQuery(rect.ll(shipSearchArea), rect.ur(shipSearchArea), {callScript = "setSpecies", callScriptArgs = {self.species}})
    self.hasUpdatedShip = #ships > 0
  end
end

function queryPlayers()
  local newPlayerList = world.entityQuery(rect.ll(self.broadcastArea), rect.ur(self.broadcastArea), {includedTypes = {"player"}})
  local newPlayers = {}
  for _, id in pairs(newPlayerList) do
    if not self.containsPlayers[id] then
      world.sendEntityMessage(id, "hylotloriginManagerId", entity.id())
    end
    newPlayers[id] = true
  end
  self.containsPlayers = newPlayers
end
