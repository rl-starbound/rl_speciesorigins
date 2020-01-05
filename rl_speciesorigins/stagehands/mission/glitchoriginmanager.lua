require "/scripts/rect.lua"

function init()
  self.containsPlayers = {}
  self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
  self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())

  message.setHandler("activateBeamaxe", function(...)
      local beamaxeSearchArea = rect.translate({300, 40, 340, 60}, entity.position())
      world.objectQuery(rect.ll(beamaxeSearchArea), rect.ur(beamaxeSearchArea), {callScript = "showBeamaxe"})
    end)

  message.setHandler("midpointSwitch", function(...)
      world.setSkyTime(config.getParameter("badTime"))
      world.setProperty("nonCombat", false)
    end)

  message.setHandler("removeNPCs", function(...)
      local npcSearchArea = rect.translate({0, -20, 300, 40}, entity.position())
      world.npcQuery(rect.ll(npcSearchArea), rect.ur(npcSearchArea), {callScript = "status.setResource", callScriptArgs = {"health", 0}})
    end)

  message.setHandler("setSpecies", function(_, _, species) self.species = species end)

  message.setHandler("unlockArmoryDoor", function(...)
      local doorSearchArea = rect.translate({265, 0, 275, 10}, entity.position())
      world.objectQuery(rect.ll(doorSearchArea), rect.ur(doorSearchArea), {callScript = "unlockDoor"})
    end)

  world.setSkyTime(config.getParameter("goodTime"))

  self.hasUpdatedShip = false
end

function update(dt)
  world.loadRegion(self.signalRegion)
  queryPlayers()

  if self.species and not self.hasUpdatedShip then
    local shipSearchArea = rect.translate({620, -50, 720, 50}, entity.position())
    local ships = world.objectQuery(rect.ll(shipSearchArea), rect.ur(shipSearchArea), {callScript = "setSpecies", callScriptArgs = {self.species}})
    self.hasUpdatedShip = #ships > 0
  end
end

function queryPlayers()
  local newPlayerList = world.entityQuery(rect.ll(self.broadcastArea), rect.ur(self.broadcastArea), {includedTypes = {"player"}})
  local newPlayers = {}
  for _, id in pairs(newPlayerList) do
    if not self.containsPlayers[id] then
      world.sendEntityMessage(id, "glitchoriginManagerId", entity.id())
    end
    newPlayers[id] = true
  end
  self.containsPlayers = newPlayers
end
