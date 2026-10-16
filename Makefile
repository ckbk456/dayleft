.NOTPARALLEL:
.PHONY: setup doctor generate lint format test build check app open

setup doctor generate lint format test build check app open:
	@bash scripts/dev.sh $@
