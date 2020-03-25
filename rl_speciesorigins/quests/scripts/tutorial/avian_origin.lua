require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")
require("/quests/scripts/speciesoriginsutil.lua")

function init()
  message.setHandler("enterMissionArea", function(_, _, areaName)
      stageEnterArea(areaName)
    end)

  message.setHandler("avianoriginManagerId", function(_, _, id)
      self.managerId = id
      world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
    end)

  message.setHandler("activateWingChest", function(...)
      quest.setIndicators({"wingchest"})
    end)

  message.setHandler("openTowerRoofDoor", function(...)
      world.sendEntityMessage(self.managerId, "openTowerRoofDoor")
    end)

  message.setHandler("giveBeamaxe", function(...)
      setStage(8)
    end)

  self.coroutines = {}

  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.beamaxeUuid = "avianbeamaxe"
  self.weaponchestUuid = "weaponchest"

  quest.setParameter("wingchest", {type = "item", item = "chestmedavian1"})
  quest.setParameter("beamaxe", {type = "item", item = "avianbeamaxe"})
  quest.setParameter("weaponChest", {type = "item", item = "weaponchest"})
  quest.setIndicators({})

  setPortraits()

  self.startingMusicTimer = config.getParameter("startingMusicTime")

  self.pesterTimer = 0

  self.missionStage = 0
  setStage(1)

  status.setPersistentEffects("protectorateProtection", {
    { stat = "breathProtection", amount = 1.0 },
    { stat = "fallDamageMultiplier", effectiveMultiplier = 0.0}
  })
end

function questStart()
  if not player.essentialItem("inspectiontool") then
    player.giveEssentialItem("inspectiontool", "inspectionmode")
  end

  if player.introComplete() then
    if not player.essentialItem("beamaxe") then
      -- This runs when you create a character and skip the intro.
      player.giveEssentialItem("beamaxe", "beamaxe")
      for _, item in pairs(config.getParameter("skipIntroItems", {})) do
        player.giveItem(item)
      end
      givePostQuestItems()
    end
    quest.complete()
    return
  end

  storage.starterChest = player.equippedItem("chest")
  storage.starterLegs = player.equippedItem("legs")
end

function questComplete()
  if not player.introComplete() then
    -- This runs when you create a character and play through the intro.
    givePostQuestItems()
  end

  player.setIntroComplete(true)

  questutil.questCompleteActions()
end

function givePostQuestItems()
  -- We may want to give the player certain items after the quest completes,
  -- but we don't want those items to be considered rewards.
  for _, item in pairs(config.getParameter("postQuestItems", {})) do
    player.giveItem(item)
  end
end

function update(dt)
  if self.startingMusicTimer > 0 then
    self.startingMusicTimer = self.startingMusicTimer - dt
    if self.startingMusicTimer <= 0 then
      world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("startingMusicTracks"))
    end
  end

  speciesoriginsutil.updateCoroutines(self.coroutines)

  updateStage(dt)

  updatePester(dt)
end

function uninit()
  status.clearPersistentEffects("protectorateProtection")

  if quest.state() == "Active" then
    -- player hasn't finished the mission
    -- confiscate any items they got during this attempt
    for _, item in pairs(config.getParameter("confiscateItems", {})) do
      player.consumeItem(item, true)
    end
    player.consumeItem(storage.starterChest)
    player.consumeItem(storage.starterLegs)

    player.consumeCurrency("money", player.currency("money"))

    player.removeEssentialItem("beamaxe")

    -- cleanup and sort inventory to put default clothes back into slots
    player.cleanupItems()
    player.giveItem(storage.starterChest)
    player.giveItem(storage.starterLegs)
  end
end

-- MISSION STAGES
-- 1 - start -> exit bed
-- 2 - drop
-- 3 - dropped
-- 4 - interacted
-- 5 - climb
-- 6 - leapt
-- 7 - find mm
-- 8 - has mm
-- 9 - weaponarea
-- 10 - reach ship -> finish

function setStage(newStage)
  if newStage > self.missionStage then
    if newStage == 1 then
      self.hasLounged = false
      self.hasWeapon = false
      if not player.introComplete() then
        player.playCinematic(config.getParameter("openingCinematic"))
      end
      setPester("avianOriginWakeUpPester", 15)
      quest.setObjectiveList({{config.getParameter("descriptions.wake"), false}})
    elseif newStage == 2 then
      setPester("avianOriginDropPester", 40)
      world.sendEntityMessage(self.managerId, "activateBeamaxe")
    elseif newStage == 3 then
      setPester("avianOriginInteractPester", 40)
    elseif newStage == 4 then
      setPester()
    elseif newStage == 5 then
      setPester("avianOriginJumpPester", 40)
    elseif newStage == 6 then
      quest.setIndicators({})
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
      world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("midpointMusicTracks"))
    elseif newStage == 7 then
      quest.setIndicators({"beamaxe"})
      quest.setObjectiveList({{config.getParameter("descriptions.matterManipulator"), false}})
      speciesoriginsutil.addCoroutine(self.coroutines, "pointTo",
        speciesoriginsutil.pointToUniqueEntity(self.beamaxeUuid,
          self.compassUpdate, function() return self.missionStage < 8 end))
      player.radioMessage("avianOriginFindBeamaxe")
    elseif newStage == 8 then
      quest.setIndicators({})
      player.giveEssentialItem("beamaxe", "beamaxe")
      world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/beamaxe.cinematic")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
    elseif newStage == 9 then
      quest.setIndicators({"weaponChest"})
      quest.setObjectiveList({{config.getParameter("descriptions.weapon"), false}})
      speciesoriginsutil.addCoroutine(self.coroutines, "pointTo",
        speciesoriginsutil.pointToUniqueEntity(self.weaponchestUuid,
          self.compassUpdate, function() return not player.hasItem("brokenprotectoratebroadsword") end))
      player.radioMessage("avianOriginWeapon")
    elseif newStage == 10 then
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("endpointCinematic"))
      self.missionCompleteTimer = 2.0
    end
    self.missionStage = newStage
  end
end

function updateStage(dt)
  if self.missionStage < 6 then
    mcontroller.controlModifiers({runningSuppressed = true})
  end

  if self.missionStage == 1 then
    if self.hasLounged == false then
      local loungeables = world.loungeableQuery(entity.position(), 10, {order = "nearest"})
      if #loungeables > 0 then
        self.hasLounged = player.lounge(loungeables[1])
      end
    end

    if self.hasLounged and not player.isLounging() then
      setStage(2)
    end
  elseif self.missionStage == 4 then
    if hasUniform() then
      quest.setIndicators({})
    end
  elseif self.missionStage == 9 and not self.hasWeapon then
    if player.hasItem("brokenprotectoratebroadsword") then
      self.hasWeapon = true
      quest.setIndicators({})
      world.sendEntityMessage(self.managerId, "unlockArmoryDoor")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
      player.radioMessage("avianOriginWeaponTutorial")
    end
  elseif self.missionStage == 10 then
    if self.missionCompleteTimer > 0 then
      self.missionCompleteTimer = self.missionCompleteTimer - dt
      if self.missionCompleteTimer <= 0 then
        player.warp("ownship")
        quest.complete()
      end
    end
  end
end

-- MISSION AREAS
-- dropped
-- interacted
-- climb
-- jumped
-- leapt
-- temple
-- wall
-- weaponarea
-- ship

function stageEnterArea(areaName)
  if areaName == "dropped" then
    setStage(3)
  elseif areaName == "interacted" then
    setStage(4)
  elseif areaName == "climb" then
    setStage(5)
  elseif areaName == "jumped" then
    setPester()
  elseif areaName == "leapt" then
    setStage(6)
  elseif areaName == "temple" then
    setStage(7)
  elseif areaName == "wall" then
    if self.missionStage < 8 then
      player.radioMessage("avianOriginNeedBeamaxe")
    else
      player.radioMessage("avianOriginUseBeamaxe")
    end
  elseif areaName == "weaponarea" then
    setStage(9)
  elseif areaName == "ship" then
    setStage(10)
  end
end

function hasUniform()
  return player.hasItem("tribalwingsback")
end

function setPester(messageId, timeout)
  self.pesterMessage = messageId
  self.pesterTimer = timeout or 0
end

function updatePester(dt)
  if self.pesterTimer > 0 then
    self.pesterTimer = self.pesterTimer - dt
    if self.pesterTimer <= 0 then
      player.radioMessage(self.pesterMessage)
    end
  end
end
