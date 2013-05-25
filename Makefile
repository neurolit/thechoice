
.PHONY: haml sass coffee resources

all: clean haml sass coffee resources
	@echo "Game built!"

haml:
	haml haml/index.haml output/index.html
	@echo "HAML compiled!"

sass:
	sass sass/choice.sass output/choice.css
	@echo "SASS compiled!"

coffee:
	coffee -c -o output/ coffee/choice.coffee
	@echo "CoffeeScript compiled!"

resources:
	cp -rf resources/* output/
	@echo "Resources installed!"

clean:
	mkdir -p output
	rm -rf output/*

