## Default formatting values for the printing tools below
DEBUG_DEFAULT_HDR_WIDTH:=130
DEBUG_DEFAULT_HDR_FG:=32
DEBUG_DEFAULT_HDR_CHAR:==


## Print bold header, n chars
## e.g.
##    ==============================================================================
##    | DB Vars
##    ==============================================================================
##
## https://misc.flogisoft.com/bash/tip_colors_and_formatting for bash format details
##
## e.g. $(call dump_header, $(DEBUG_DEFAULT_HDR_WIDTH), "SOME HEADER", $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))
define dump_header
	@$(eval HDR_WIDTH:=$(1))
	@$(eval HDR_MSG:=$(2))
	@$(eval HDR_CHAR:=$(3))
	@$(eval HDR_FG:=$(4))
	@printf "\e[$(HDR_FG)m%0.s$(HDR_CHAR)\e[0m" {1..$(HDR_WIDTH)}
	@printf "\n"
	@printf "\e[1;$(HDR_FG)m| %s \e[0m" $(HDR_MSG)
	@printf "\n"
	@printf "\e[$(HDR_FG)m%0.s$(HDR_CHAR)\e[0m" {1..$(HDR_WIDTH)}
	@echo ""
endef

## Print a simple separator, n chars
## e.g.
##    ==============================================================================
##
## https://misc.flogisoft.com/bash/tip_colors_and_formatting for bash format details
##
## e.g. $(call sep_line, $(DEBUG_DEFAULT_HDR_WIDTH), $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))

define sep_line
	@$(eval HDR_WIDTH:=$(1))
	@$(eval HDR_CHAR:=$(2))
	@$(eval HDR_FG:=$(3))
	@printf "\e[$(HDR_FG)m%0.s$(HDR_CHAR)\e[0m" {1..$(HDR_WIDTH)}
	@printf "\n"
endef

sepr:
	$(call sep_line, $(DEBUG_DEFAULT_HDR_WIDTH), $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))

## Dump prettified version of a var e.g. DB_CONTAINER - mick rulez
## column width of 30, ##e.g.
##   DB_CONTAINER               - micks-db
##   DB_USER                   	- some-user
## nb: 033 is yellow
##
define dump_var
	@echo $(1) $(2) $(origin 1) | awk -v width=30 '{printf "  \033[33m%-*s\033[0m - %-*s \033[34m%s\033[0m\n", width, $$1, (width + 25), $$2, $$3}'
endef

# HELP - will output the help for each task in the Makefile
# In sorted order.
# The width of the first column can be determined by the `width` value passed to awk
#
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html for the initial version.
#
help: ## This help.
	@grep -E -h "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) \
	  | sort \
	  | awk -v width=36 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-*s\033[0m %s\n", width, $$1, $$2}'

