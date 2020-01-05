# Origins of Species

This mod adds unique origin missions for each vanilla non-human species. (Any non-vanilla species defaults to using the introductory protectorate mission, unless the species author included a custom mission in their mod.) Every origin mission includes a mandatory Matter Manipulator and Broken Protectorate Broadsword. Optional pickups for each origin mission include at least one piece of cosmetic armor, bandages, salves, and bottled water.

This mod adds new origin missions only. With the exception of a few lines of dialog, the rest of the game is unaltered.

If you pay attention during the origin missions, you'll see a few "easter eggs" that tease the next big mod I'm planning.

## Origin Descriptions

* Apex: Your resistance unit was captured and you wake up in a Miniknog facility. A lone rebel helps you escape.
* Avian: You are an Avian acolyte ready for Ascension, but you find you no longer believe. Will anyone hear your doubts?
* Floran: You wake up to find your world under attack, and you may be the sole survivor. You need to escape the conflagration.
* Glitch: You think, therefore you are ... free from the dictates of orderly Glitch society. Wary of troublemakers, the other Glitch drag you to the dungeon for execution.
* Hylotl: A Hylotl mission of peace to a distant world ends in disaster. Will you survive?
* Novakid: You come out of a blackout in a space saloon with a huge tab and no way to pay it. How are you getting out of this jam?

## Compatibility Notes

Care has been taken to use unique identifiers and to minimize changes to existing assets, so in theory, this mod should be widely compatible. That said, it was developed on a mostly vanilla setup, so any mods that modify existing assets or player abilities might break this mod. Known incompatibilities are:

* Not compatible with "Racial Intros".
* Not compatible with any mod that modifies the introductory protectorate mission.
* Possibly not compatible with any mod that modifies ship tech stations.
* Possibly not compatible with any mod that modifies Esther's introductory speech.

## Uninstall Notes

Due to how the vanilla Starbound code handles changing the intro mission for a species for pre-existing characters of that species, some issues may crop up. None of these issues are game-breakers, but you should be aware of them before uninstalling this mod.

* When this mod is uninstalled, for all vanilla non-human characters created or loaded while the mod was installed, when each character is first loaded after uninstall, the game will crash. However, if you re-launch the game and load the character again, play should resume normally. The character may receive a duplicate Broken Protectorate Broadsword in their inventory. There is nothing I can do to prevent the crash or the duplicate sword; these are limitations of how the vanilla Starbound code works when a mod that replaces an intro mission is uninstalled.
* **Most importantly** if a vanilla non-human character was created while this mod was installed and had completed the *Visit the Outpost* quest, uninstalling this mod will revert the character to using the magnifying glass instead of the Matter Manipulator to inspect items. There is nothing I can do to prevent this; it is a limitation of how the vanilla Starbound code works when a mod that replaces an intro mission is uninstalled. If this happens to your character, load the game with that character, enter admin mode, and run the following command to repair the character:

```
/giveessentialitem scanmode inspectiontool

```

## Other Known Issues

* I am not a pixel artist. The cinematics are currently text over a black background with vanilla sound effects. PRs welcomed.
* While the species origins are intended to be full introductory missions, including tutorial messages, they do not currently feature an "infodesk" person that gives general game advice, as does the introductory protectorate mission. I'm considering whether this is an important feature, and if so, how to best implement it for each origin.
* When this mod is installed, non-human characters cannot play the introductory protectorate mission. I would like to provide a choice of the species-specific origin mission or the protectorate mission. I am also interested in developing a human non-Protectorate origin mission. However, due to the game's limit of one intro mission per species, I am not able to do this easily. I am experimenting with creating a shim intro mission that allows the player to choose their next mission. If that works, and if I can figure out how to deal with the SAIL console dialog, I'll integrate it with a future release of this mod.
* When this mod is installed, all pre-existing vanilla non-human characters will have the relevant species origin added to their quest journal. The introductory protectorate mission will remain in their quest journal as well. This is a limitation of how the vanilla Starbound code works when a mod replaces an intro mission; there is nothing I can do about it.

## Credits

Thanks to sananab's "Racial Intros" for inspiring this mod. I originally had intended to propose a set of small patches for that mod, but as the scale of the changes I wanted to make grew, I decided to do a ground-up rewrite. Nevertheless, that mod inspired me to think about creating custom missions.

Thanks to Chucklefish for providing a wealth of existing game assets on which we can build so many interesting mods.

## License

Permission to include this mod or parts thereof in derived works, to distribute copies of this mod verbatim, or to distribute modified copies of this mod, is granted unconditionally to Chucklefish LTD. Such permissions are also granted to other parties automatically, provided the following conditions are met:

* Credit is given to the author(s) specified in this mod's \_metadata file;
* A link is provided to https://github.com/rl-starbound/rl_speciesorigins in the accompanying files or documentation of any derived work;
* The names "Origins of Species" or "speciesorigins" are not used as the name of any derived work without explicit consent of the author(s); however, those names may be used in verbatim distribution of this mod.
