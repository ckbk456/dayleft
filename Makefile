.NOTPARALLEL:
.PHONY: setup doctor generate lint format test build check open

setup doctor generate lint format test build check open:
	@bash scripts/dev.sh $@
