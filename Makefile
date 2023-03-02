ifneq (grouped-target, $(findstring grouped-target,$(.FEATURES)))
ERROR:=$(error This version of make does not support required 'grouped-target' (try GNU make 4.3+).)
endif

SHELL:=/usr/bin/env bash
.DELETE_ON_ERROR:
.PRECIOUS: last-lint.txt last-test.txt
.PHONY: all build dependency-graph lint lint-fix qa test

default: build

all: build

BASH_ROLLUP:=npx bash-rollup
CATALYST_SCRIPTS:=npx catalyst-scripts

SRC:=src
DIST:=dist

TEST_STAGING:=test-staging
LIQ_SRC:=$(SRC)/liq
LIQ_FILES:=$(shell find "$(LIQ_SRC)" -not -name "*.test.*" -not -path "*/test/*" -type f)
LIQ_TEST_SRC_FILES:=$(shell find $(LIQ_SRC) -name "*.js" -o -name "*.mjs")
LIQ_ALL_FILES:=$(LIQ_TEST_SRC_FILES)
LIQ_TEST_BUILT_FILES=$(patsubst %.mjs, %.js, $(patsubst $(LIQ_SRC)/%, test-staging/%, $(LIQ_TEST_SRC_FILES)))
LIQ_JS:=$(DIST)/liq.js
LIQ_BIN:=$(DIST)/liq

COMPLETION_BIN:=$(DIST)/completion.sh
COMPLETION_SRC:=$(SRC)/completion
COMPLETION_FILES:=$(COMPLETION_SRC)/liq-completion.sh

INSTALL_BIN:=$(DIST)/install.sh
INSTALL_SRC:=$(SRC)/install
INSTALL_FILES:=$(INSTALL_SRC)/install.sh

BUILD_FILES:=$(LIQ_BIN) $(COMPLETION_BIN) $(INSTALL_BIN)

build: $(BUILD_FILES)

$(COMPLETION_BIN): $(COMPLETION_FILES) $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

$(INSTALL_BIN): $(INSTALL_FILES) $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

$(LIQ_JS): package.json $(LIQ_FILES)
	JS_SRC=$(LIQ_SRC) $(CATALYST_SCRIPTS) build

$(LIQ_BIN): $(LIQ_JS)
	@echo -en "\nCreating 'liq' bash wrapper... "
	@echo '#!/usr/bin/env bash' > $@
	@SCRIPT_DIR="$${PWD}/dist" && echo "/usr/bin/env node --no-warnings '$${SCRIPT_DIR}/liq.js'" '"$$@"' >> $@
	@echo "done."
	chmod a+x "$@"

$(LIQ_TEST_BUILT_FILES) &: $(LIQ_TEST_SRC_FILES)
	JS_SRC=$(LIQ_SRC) $(CATALYST_SCRIPTS) pretest

last-test.txt: $(LIQ_TEST_BUILT_FILES)
	( set -e; set -o pipefail; \
		JS_SRC=$(TEST_STAGING) TEST_MODE=true $(CATALYST_SCRIPTS) test 2>&1 | tee last-test.txt; )

test: last-test.txt

# lint rules
last-lint.txt: $(LIQ_ALL_FILES)
	( set -e; set -o pipefail; \
		JS_LINT_TARGET=$(LIQ_SRC) $(CATALYST_SCRIPTS) lint | tee last-lint.txt; )

lint: last-lint.txt

lint-fix:
	JS_LINT_TARGET=$(LIQ_SRC) $(CATALYST_SCRIPTS) lint-fix

qa: test lint

clean:
	rm -f dist/*

dependency-graph:
	make -Bnd test-cli | make2graph | dot -Tpng -o out.png
