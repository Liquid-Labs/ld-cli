LIQ2_SRC:=src/liq2
LIQ2_FILES:=$(shell find "$(LIQ2_SRC)" -not -name "*.test.*" -not -path "*/test/*" -type f)
LIQ2_TEST_SRC_FILES:=$(shell find $(LIQ2_SRC) -name "*.js" -o -name "*.mjs")
LIQ2_TEST_BUILT_FILES=$(patsubst %.mjs, %.js, $(patsubst $(LIQ2_SRC)/%, test-staging/%, $(LIQ2_TEST_SRC_FILES)))
LIQ2_JS:=dist/liq2.js
LIQ2_BIN:=dist/liq2
BUILD_FILES:=$(BUILD_FILES) $(LIQ2_BIN)

$(LIQ2_JS): package.json $(LIQ2_FILES)
	JS_SRC=$(LIQ2_SRC) $(CATALYST_SCRIPTS) build

$(LIQ2_BIN): $(LIQ2_JS)
	echo -e '#!/usr/bin/env node --no-warnings\n' > $@
	cat $< >> $@
	chmod a+x $@

$(LIQ2_TEST_BUILT_FILES) &: $(LIQ2_TEST_SRC_FILES)
	JS_SRC=$(LIQ2_SRC) $(CATALYST_SCRIPTS) pretest

TESTS:=$(TESTS) test-cli

test-cli: $(LIQ2_TEST_BUILT_FILES)
	JS_SRC=test-staging $(CATALYST_SCRIPTS) test
