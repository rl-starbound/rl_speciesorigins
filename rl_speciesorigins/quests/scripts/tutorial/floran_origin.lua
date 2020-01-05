require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  message.setHandler("enterMissionArea", function(_, _, areaName)
      stageEnterArea(areaName)
    end)

  message.setHandler("floranoriginManagerId", function(_, _, id)
      self.managerId = id
      world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
    end)

  message.setHandler("giveBeamaxe", function(...)
      setStage(7)
    end)

  quest.setParameter("beamaxe", {type = "item", item = "floranbeamaxe"})
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
-- 2 - home
-- 3 - outside
-- 4 - blocked
-- 5 - searchroom
-- 6 - hiddenroom
-- 7 - has MM
-- 8 - crater
-- 9 - has weapon
-- 10 - reach ship -> finish

function setStage(newStage)
  if newStage > self.missionStage then
    if newStage == 1 then
      self.hasLounged = false
      if not player.introComplete() then
        player.playCinematic(config.getParameter("openingCinematic"))
      end
      quest.setObjectiveList({{config.getParameter("descriptions.burning"), false}})
    elseif newStage == 2 then
      setPester("floranOriginStairsPester", 30)
      player.radioMessage("floranOriginReason")
    elseif newStage == 3 then
      setPester("floranOriginDoorPester", 30)
      quest.setObjectiveList({{config.getParameter("descriptions.investigate"), false}})
      player.radioMessage("floranOriginInvestigate")
    elseif newStage == 4 then
      setPester("floranOriginDropDownPester", 30)
    elseif newStage == 5 then
      player.radioMessage("floranOriginSearch")
    elseif newStage == 6 then
      world.sendEntityMessage(self.managerId, "activateBeamaxe")
      quest.setIndicators({"beamaxe"})
      player.radioMessage("floranOriginTakeBeamaxe")
    elseif newStage == 7 then
      quest.setIndicators({})
      player.giveEssentialItem("beamaxe", "beamaxe")
      world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/beamaxe.cinematic")
    elseif newStage == 8 then
      quest.setIndicators({"weaponChest"})
      player.radioMessage("floranOriginCrater")
    elseif newStage == 9 then
      quest.setIndicators({})
      world.sendEntityMessage(self.managerId, "unlockArmoryDoor")
      player.radioMessage("floranOriginWeaponTutorial")
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
          setPester("floranOriginExitBedPester", 15)
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
-- jumped
-- outside
-- wrong
-- kitchen
-- blocked
-- dropped
-- searchroom
-- hiddenroom
-- crater
-- ship

function stageEnterArea(areaName)
  if areaName == "jumped" and self.missionStage < 3 then
    setPester()
  elseif areaName == "outside" then
    setStage(3)
  elseif areaName == "wrong" and self.missionStage < 4 then
    setPester()
  elseif areaName == "kitchen" and self.missionStage < 4 then
    setPester()
  elseif areaName == "blocked" then
    setStage(4)
    player.radioMessage("floranOriginBlocked")
  elseif areaName == "dropped" then
    setPester()
  elseif areaName == "searchroom" then
    setStage(5)
  elseif areaName == "hiddenroom" then
    setStage(6)
  elseif areaName == "crater" then
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
