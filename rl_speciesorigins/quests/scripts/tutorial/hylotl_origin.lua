require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  message.setHandler("enterMissionArea", function(_, _, areaName)
      stageEnterArea(areaName)
    end)

  message.setHandler("hylotloriginManagerId", function(_, _, id)
      self.managerId = id
      world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
    end)

  message.setHandler("activateBeamaxe", function(...)
      setStage(4)
    end)

  message.setHandler("giveBeamaxe", function(...)
      setStage(5)
    end)

  quest.setParameter("beamaxe", {type = "item", item = "hylotlbeamaxe"})
  quest.setParameter("weaponChest", {type = "item", item = "weaponchest"})
  quest.setIndicators({})

  setPortraits()

  self.startingMusicTimer = config.getParameter("startingMusicTime")
  self.midpointMusicTimer = 0

  self.pesterTimer = 0
  self.weaponPesterTimer = 0

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

    -- Take away the flashlight; another is provided on the ship.
    player.consumeItem("flashlight")
    player.cleanupItems()
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

  if self.midpointMusicTimer > 0 then
    self.midpointMusicTimer = self.midpointMusicTimer - dt
    if self.midpointMusicTimer <= 0 then
      world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("midpointMusicTracks"))
    end
  end

  updateStage(dt)

  updatePester(dt)
  updateWeaponPester(dt)
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
-- 1 - start -> daydreaming
-- 2 - campfire
-- 3 - sleep -> midpoint
-- 4 - get beamaxe
-- 5 - got beamaxe
-- 6 - overrun
-- 7 - dropped
-- 8 - jumped
-- 9 -
-- 10 - reach ship -> finish

function setStage(newStage)
  if newStage > self.missionStage then
    if newStage == 1 then
      self.hasWeapon = false
      if not player.introComplete() then
        player.playCinematic(config.getParameter("openingCinematic"))
      end
      quest.setObjectiveList({{config.getParameter("descriptions.explore"), false}})
    elseif newStage == 2 then
      quest.setObjectiveList({{config.getParameter("descriptions.sleep"), false}})
    elseif newStage == 3 then
      self.midpointTransitionTimer = 2.0
      self.midpointMusicTimer = config.getParameter("midpointMusicTime")
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("midpointCinematic"))
    elseif newStage == 4 then
      setPester("hylotlOriginInteractPester", 30)
      world.sendEntityMessage(self.managerId, "activateBeamaxe")
      quest.setIndicators({"beamaxe"})
    elseif newStage == 5 then
      setPester("hylotlOriginBeamaxePester", 8)
      quest.setIndicators({})
      player.giveEssentialItem("beamaxe", "beamaxe")
      world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/beamaxe.cinematic")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
    elseif newStage == 6 then
      world.sendEntityMessage(self.managerId, "overrunBarricade")
      player.radioMessage("hylotlOriginOverrun1")
      player.radioMessage("hylotlOriginOverrun2")
      setPester("hylotlOriginOverrun3", 10)
    elseif newStage == 7 then
      setPester()
      setWeaponPester(4)
    elseif newStage == 8 then
      setPester()
    elseif newStage == 10 then
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("endpointCinematic"))
      self.missionCompleteTimer = 2.0
    end
    self.missionStage = newStage
  end
end

function updateStage(dt)
  if self.missionStage < 3 then
    mcontroller.controlModifiers({runningSuppressed = true})
  end
  if self.missionStage == 3 then
    if self.midpointTransitionTimer > 0 then
      self.midpointTransitionTimer = self.midpointTransitionTimer - dt
      if self.midpointTransitionTimer <= 0 then
        world.sendEntityMessage(self.managerId, "midpointSwitch")
        mcontroller.setPosition(config.getParameter("midpointTeleportPosition"))

        self.hasLounged = false
        player.giveItem("flashlight")
        quest.setObjectiveList({{config.getParameter("descriptions.matterManipulator"), false}})
      end
    end

    if self.hasLounged == false then
      local loungeables = world.loungeableQuery(entity.position(), 10, {order = "nearest"})
      if #loungeables > 0 then
        self.hasLounged = player.lounge(loungeables[1])
        if self.hasLounged then
          setPester("hylotlOriginExitBedPester", 56)
        end
      end
    end

    if self.hasLounged and not player.isLounging() then
      setPester()
    end
  elseif self.missionStage >= 7 and not self.hasWeapon then
    if player.hasItem("brokenprotectoratebroadsword") then
      self.hasWeapon = true
      quest.setIndicators({})
      world.sendEntityMessage(self.managerId, "openMineHatch")
      player.radioMessage("hylotlOriginWeaponTutorial")
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
-- campfire
-- sleep
-- overrun
-- drop
-- dropped
-- jump
-- jumped
-- ship

function stageEnterArea(areaName)
  if areaName == "campfire" then
    setStage(2)
  elseif areaName == "sleep" then
    setStage(3)
  elseif areaName == "overrun" then
    setStage(6)
  elseif areaName == "drop" and self.missionStage < 7 then
    setPester("hylotlOriginDropPester", 30)
  elseif areaName == "dropped" then
    setStage(7)
  elseif areaName == "jump" and self.missionStage < 8 then
    setPester("hylotlOriginJumpPester", 30)
  elseif areaName == "jumped" then
    setStage(8)
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

function setWeaponPester(timeout)
  self.weaponPesterTimer = timeout or 0
end

function updateWeaponPester(dt)
  if self.weaponPesterTimer > 0 then
    self.weaponPesterTimer = self.weaponPesterTimer - dt
    if self.weaponPesterTimer <= 0 then
      quest.setIndicators({"weaponChest"})
      player.radioMessage("hylotlOriginGetWeaponPester")
    end
  end
end
