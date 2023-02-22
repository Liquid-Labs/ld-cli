LIQ2_SRC:=src/liq2
LIQ2_FILES:=$(shell find "$(LIQ2_SRC)" -not -name "*.test.*" -not -path "*/test/*" -type f)
LIQ2_TEST_SRC_FILES:=$(shell find $(LIQ2_SRC) -name "*.js" -o -name "*.mjs")
LIQ2_ALL_FILES:=$(LIQ2_TEST_SRC_FILES)
LIQ2_TEST_BUILT_FILES=$(patsubst %.mjs, %.js, $(patsubst $(LIQ2_SRC)/%, test-staging/%, $(LIQ2_TEST_SRC_FILES)))
LIQ2_JS:=dist/liq2.js
LIQ2_BIN:=dist/liq2
BUILD_FILES:=$(BUILD_FILES) $(LIQ2_BIN)

$(LIQ2_JS): package.json $(LIQ2_FILES)
	JS_SRC=$(LIQ2_SRC) $(CATALYST_SCRIPTS) build

$(LIQ2_BIN): $(LIQ2_JS)
	@echo -n "Writing bash wrapper... "
	@echo '#!/usr/bin/env sh' > $@
	@SCRIPT_DIR="$${PWD}/dist" && echo "/usr/bin/env node --no-warnings '$${SCRIPT_DIR}/liq2.js'" '"$$@"' >> $@
	@echo "done."
	chmod a+x "$@"

$(LIQ2_TEST_BUILT_FILES) &: $(LIQ2_TEST_SRC_FILES)
	JS_SRC=$(LIQ2_SRC) $(CATALYST_SCRIPTS) pretest

TESTS:=$(TESTS) test-cli

test-cli: $(LIQ2_TEST_BUILT_FILES)
	JS_SRC=test-staging $(CATALYST_SCRIPTS) test


last-test.txt: $(LIQ2_TEST_BUILT_FILES)
	( set -e; set -o pipefail; \
		JS_SRC=$(TEST_STAGING) TEST_MODE=true $(CATALYST_SCRIPTS) test 2>&1 | tee last-test.txt; )

test: last-test.txt

# lint rules
last-lint.txt: $(LIQ2_ALL_FILES)
	( set -e; set -o pipefail; \
		JS_LINT_TARGET=$(LIQ_CLI_SRC) $(CATALYST_SCRIPTS) lint | tee last-lint.txt; )

lint: last-lint.txt

lint-fix:
	JS_LINT_TARGET=$(LIQ_CLI_SRC) $(CATALYST_SCRIPTS) lint-fix
