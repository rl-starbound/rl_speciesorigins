require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")
require("/quests/scripts/speciesoriginsutil.lua")

function init()
  message.setHandler("enterMissionArea", function(_, _, areaName)
      stageEnterArea(areaName)
    end)

  message.setHandler("novakidoriginManagerId", function(_, _, id)
      self.managerId = id
      world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
    end)

  message.setHandler("activateWeaponChest", function(...)
      if not player.hasItem("brokenprotectoratebroadsword") then
        quest.setIndicators({"weaponChest"})
        quest.setObjectiveList({{config.getParameter("descriptions.weapon"), false}})
        speciesoriginsutil.addCoroutine(self.coroutines, "pointTo",
          speciesoriginsutil.pointToUniqueEntity(self.weaponchestUuid,
            self.compassUpdate, function() return self.missionStage < 9 end))
      end
    end)

  message.setHandler("giveBeamaxe", function(...)
      setStage(7)
    end)

  message.setHandler("unlockKitchenDoor", function(...)
      world.sendEntityMessage(self.managerId, "unlockKitchenDoor")
      setPester("novakidOriginBill", 2)
    end)

  self.coroutines = {}

  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.beamaxeUuid = "novakidbeamaxe"
  self.weaponchestUuid = "weaponchest"

  quest.setParameter("beamaxe", {type = "item", item = "novakidbeamaxe"})
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
-- 1 - start -> exit chair
-- 2 - saloon
-- 3 - kitchen
-- 4 - grate
-- 5 - shelf
-- 6 - treasure
-- 7 - has MM
-- 8 - climb
-- 9 - has weapon
-- 10 - reach ship -> finish

function setStage(newStage)
  if newStage > self.missionStage then
    if newStage == 1 then
      self.hasLounged = false
      if not player.introComplete() then
        player.playCinematic(config.getParameter("openingCinematic"))
      end
      quest.setObjectiveList({{config.getParameter("descriptions.wake"), false}})
    elseif newStage == 2 then
      setPester()
    elseif newStage == 3 then
      setPester("novakidOriginDropPester", 40)
    elseif newStage == 4 then
      setPester("novakidOriginInteractPester", 40)
      player.radioMessage("novakidOriginGrate")
    elseif newStage == 5 then
      setPester("novakidOriginShelfPester", 20)
    elseif newStage == 6 then
      quest.setIndicators({"beamaxe"})
      world.sendEntityMessage(self.managerId, "activateBeamaxe")
      quest.setObjectiveList({{config.getParameter("descriptions.matterManipulator"), false}})
      speciesoriginsutil.addCoroutine(self.coroutines, "pointTo",
        speciesoriginsutil.pointToUniqueEntity(self.beamaxeUuid,
          self.compassUpdate, function() return self.missionStage < 7 end))
      player.radioMessage("novakidOriginTreasure")
    elseif newStage == 7 then
      setPester("novakidOriginMMPester", 10)
      quest.setIndicators({})
      player.giveEssentialItem("beamaxe", "beamaxe")
      world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/beamaxe.cinematic")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
    elseif newStage == 8 then
      setPester("novakidOriginClimbPester", 40)
    elseif newStage == 9 then
      quest.setIndicators({})
      world.sendEntityMessage(self.managerId, "unlockSheriffDoor")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
      player.radioMessage("novakidOriginWeaponTutorial")
    elseif newStage == 10 then
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("endpointCinematic"))
      self.missionCompleteTimer = 2.0
    end
    self.missionStage = newStage
  end
end

function updateStage(dt)
  if self.missionStage == 1 then
    if self.hasLounged == false then
      local loungeables = world.loungeableQuery(entity.position(), 10, {order = "nearest"})
      if #loungeables > 0 then
        self.hasLounged = player.lounge(loungeables[1])
        if self.hasLounged then
          setPester("novakidOriginGetUpPester", 20)
        end
      end
    end

    if self.hasLounged and not player.isLounging() then
      setStage(2)
    end
  elseif self.missionStage == 8 then
    if player.hasItem("brokenprotectoratebroadsword") then
      setStage(9)
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
-- kitchen
-- grate
-- shelf
-- hiddendoor
-- treasure
-- sewer
-- climb
-- manhole
-- ship

function stageEnterArea(areaName)
  if areaName == "kitchen" then
    setStage(3)
  elseif areaName == "grate" then
    setStage(4)
  elseif areaName == "shelf" then
    setStage(5)
  elseif areaName == "hiddendoor" and self.missionStage < 7 then
    setPester()
  elseif areaName == "treasure" then
    setStage(6)
  elseif areaName == "sewer" then
    setPester()
  elseif areaName == "climb" then
    setStage(8)
  elseif areaName == "manhole" then
    setPester()
  elseif areaName == "ship" then
    setStage(10)
  end
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
