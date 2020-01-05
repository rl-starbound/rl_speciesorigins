BINDIR = ${HOME}/GOG-Games/Starbound/game/linux

# Take extreme care if you put wildcards in this variable. It will be
# passed to rm.
ALL_PAKS = rl_speciesorigins.pak

%.pak: $(shell find $(@:.pak=))
	cd $(@:.pak=) && $(BINDIR)/asset_packer . ../$(@) && cd ..

all: $(ALL_PAKS)

clean:
	rm -f $(ALL_PAKS)

.PHONY: all clean
