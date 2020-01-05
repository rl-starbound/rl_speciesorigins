require "/scripts/rect.lua"

function init()
  self.containsPlayers = {}
  self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
  self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())

  message.setHandler("activateAlarm", function(...)
      local doorSearchArea = rect.translate({290, 90, 300, 100}, entity.position())
      world.objectQuery(rect.ll(doorSearchArea), rect.ur(doorSearchArea), {callScript = "closeDoor"})
      world.objectQuery(rect.ll(doorSearchArea), rect.ur(doorSearchArea), {callScript = "lockDoor"})
      local switchSearchArea = rect.translate({210, 75, 220, 85}, entity.position())
      world.objectQuery(rect.ll(switchSearchArea), rect.ur(switchSearchArea), {callScript = "onInteraction"})
      local npcSearchArea = rect.translate({-20, -25, 80, 25}, entity.position())
      world.npcQuery(rect.ll(npcSearchArea), rect.ur(npcSearchArea), {callScript = "status.setResource", callScriptArgs = {"health", 0}})
    end)

  message.setHandler("activateBeamaxe", function(...)
      local beamaxeSearchArea = rect.translate({230, -30, 270, -10}, entity.position())
      world.objectQuery(rect.ll(beamaxeSearchArea), rect.ur(beamaxeSearchArea), {callScript = "showBeamaxe"})
    end)

  message.setHandler("openCellDoor", function(...)
      local doorSearchArea = rect.translate({5, -5, 15, 5}, entity.position())
      world.objectQuery(rect.ll(doorSearchArea), rect.ur(doorSearchArea), {callScript = "openDoor"})
    end)

  message.setHandler("setSpecies", function(_, _, species) self.species = species end)

  message.setHandler("unlockArmoryDoor", function(...)
      local doorSearchArea = rect.translate({300, 60, 310, 70}, entity.position())
      world.objectQuery(rect.ll(doorSearchArea), rect.ur(doorSearchArea), {callScript = "unlockDoor"})
    end)

  world.setSkyTime(config.getParameter("badTime"))

  self.hasUpdatedShip = false
end

function update(dt)
  world.loadRegion(self.signalRegion)
  queryPlayers()

  if self.species and not self.hasUpdatedShip then
    local shipSearchArea = rect.translate({350, 150, 450, 250}, entity.position())
    local ships = world.objectQuery(rect.ll(shipSearchArea), rect.ur(shipSearchArea), {callScript = "setSpecies", callScriptArgs = {self.species}})
    self.hasUpdatedShip = #ships > 0
  end
end

function queryPlayers()
  local newPlayerList = world.entityQuery(rect.ll(self.broadcastArea), rect.ur(self.broadcastArea), {includedTypes = {"player"}})
  local newPlayers = {}
  for _, id in pairs(newPlayerList) do
    if not self.containsPlayers[id] then
      world.sendEntityMessage(id, "apexoriginManagerId", entity.id())
    end
    newPlayers[id] = true
  end
  self.containsPlayers = newPlayers
end
