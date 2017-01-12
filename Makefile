SHELL        := /usr/bin/env bash
FREY_VERSION := 0.3.27

.PHONY: frey
frey:
	@mkdir -p node_modules
	@grep $(FREY_VERSION) node_modules/frey/package.json 2>&1 > /dev/null || npm install frey@$(FREY_VERSION)

.PHONY: provision
provision: frey
	@source env.sh && node_modules/.bin/frey install

.PHONY: launch
launch: frey
	@source env.infra.sh && node_modules/.bin/frey infra

.PHONY: console
console: frey
	@source env.sh && node_modules/.bin/frey remote

.PHONY: deploy-localfrey
deploy-localfrey: frey
	@source env.sh && babel-node ${HOME}/code/frey/src/cli.js setup

.PHONY: console-localfrey
console-localfrey: frey
	@source env.sh && babel-node ${HOME}/code/frey/src/cli.js remote
