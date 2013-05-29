
.PHONY: build compile haml sass coffee resources deploy

MINIFY := juicer merge -s
MINIFY_DEBUG := juicer merge -m none -s

build: clean compile pack resources
	@echo "Game built!"

pack:
	rm -f js/choice.min.js css/choice.min.css
	$(MINIFY) js/choice.js
	cp -f js/choice.min.js output/
	$(MINIFY) css/choice.css
	cp -f css/choice.min.css output/

compile: haml sass coffee

haml:
	haml haml/index.haml output/index.html
	@echo "HAML compiled!"

sass:
	sass sass/choice.sass css/choice.css
	@echo "SASS compiled!"

coffee:
	coffee -c -o js/ coffee/choice.coffee
	@echo "CoffeeScript compiled!"

resources:
	cp -rf resources/* output/
	@echo "Resources installed!"

clean:
	mkdir -p output
	rm -rf output/*

deploy: build
	scp -r output amos@taft:/srv/apps/production/thechoice.amos.me/

