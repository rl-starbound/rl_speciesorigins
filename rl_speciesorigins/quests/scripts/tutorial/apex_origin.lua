require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  message.setHandler("enterMissionArea", function(_, _, areaName)
      stageEnterArea(areaName)
    end)

  message.setHandler("apexoriginManagerId", function(_, _, id)
      self.managerId = id
      world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
    end)

  message.setHandler("giveBeamaxe", function(...)
      setStage(6)
    end)

  message.setHandler("openCellDoor", function(...)
      world.sendEntityMessage(self.managerId, "openCellDoor")
    end)

  quest.setParameter("uniformLocker", {type = "item", item = "apexcoolcupboard"})
  quest.setParameter("beamaxe", {type = "item", item = "apexbeamaxe"})
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
-- 2 - jump
-- 3 - jumped
-- 4 - uniform
-- 5 - protectorate
-- 6 - has MM
-- 7 - weaponarea
-- 8 - has weapon
-- 9 - alarm
-- 10 - reach ship -> finish

function setStage(newStage)
  if newStage > self.missionStage then
    if newStage == 1 then
      self.hasDropped = false
      self.hasLounged = false
      if not player.introComplete() then
        player.playCinematic(config.getParameter("openingCinematic"))
      end
      quest.setObjectiveList({{config.getParameter("descriptions.wake"), false}})
    elseif newStage == 2 then
      setPester("apexOriginJumpPester", 30)
      world.sendEntityMessage(self.managerId, "activateBeamaxe")
    elseif newStage == 3 then
      setPester("apexOriginExitCellPester", 30)
    elseif newStage == 4 then
      quest.setIndicators({"uniformLocker"})
      player.radioMessage("apexOriginUniform")
    elseif newStage == 5 then
      setPester("apexOriginDropPester", 30)
      quest.setIndicators({"beamaxe"})
      quest.setObjectiveList({{config.getParameter("descriptions.matterManipulator"), false}})
      player.radioMessage("apexOriginProtectorate")
    elseif newStage == 6 then
      setPester("apexOriginBeamaxe", 8)
      quest.setIndicators({})
      player.giveEssentialItem("beamaxe", "beamaxe")
      world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/beamaxe.cinematic")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
    elseif newStage == 7 then
      quest.setIndicators({"weaponChest"})
      player.radioMessage("apexOriginGetWeapon")
    elseif newStage == 8 then
      quest.setIndicators({})
      world.sendEntityMessage(self.managerId, "unlockArmoryDoor")
      player.radioMessage("apexOriginWeaponTutorial")
    elseif newStage == 9 then
      world.sendEntityMessage(self.managerId, "activateAlarm")
      player.radioMessage("apexOriginAlarm1")
      player.radioMessage("apexOriginAlarm2")
      player.radioMessage("apexOriginAlarm3")
      player.radioMessage("apexOriginAlarm4")
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
          setPester("apexOriginExitBedPester", 15)
        end
      end
    end

    if self.hasLounged and not player.isLounging() then
      setPester()
    end
  elseif self.missionStage == 4 and hasUniform() then
    quest.setIndicators({})
  elseif self.missionStage == 7 then
    if player.hasItem("brokenprotectoratebroadsword") then
      setStage(8)
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
-- jump
-- jumped
-- hall
-- uniform
-- protectorate
-- dropped
-- breakdoor
-- weaponarea
-- alarm
-- ship

function stageEnterArea(areaName)
  if areaName == "jump" then
    setStage(2)
  elseif areaName == "jumped" then
    setStage(3)
  elseif areaName == "hall" and self.missionStage < 4 then
    setPester()
  elseif areaName == "uniform" then
    setStage(4)
  elseif areaName == "protectorate" then
    setStage(5)
  elseif areaName == "dropped" and self.missionStage < 6 then
    self.hasDropped = true
    setPester()
  elseif areaName == "breakdoor" then
    if self.missionStage < 6 then
      player.radioMessage("apexOriginNeedBeamaxe")
    else
      player.radioMessage("apexOriginUseBeamaxe")
    end
  elseif areaName == "weaponarea" then
    setStage(7)
  elseif areaName == "alarm" then
    setStage(9)
  elseif areaName == "ship" then
    setStage(10)
  end
end

function hasUniform()
  return player.hasItem("miniknogchest") and player.hasItem("miniknogpants")
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
