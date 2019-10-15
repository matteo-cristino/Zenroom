# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js

MAX_STRING := 8000 # 512000 # 128000

javascript-demo: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-demo: ldflags += -s WASM=1 \
	-s ASSERTIONS=1 \
	--shell-file ${website}/demo/shell_minimal.html
javascript-demo: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--preload-file lua@/" \
	JSOUT="${website}/demo/index.html" \
	make -C src js
	@mkdir -p build/demo
	@cp -v ${website}/demo/index.* build/demo/
	@cp -v ${website}/demo/*.js    build/demo/

javascript-web: cflags  += -O3 -fno-exceptions -fno-rtti
javascript-web: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' \
	-s WASM_OBJECT_FILES=0
javascript-web: ldflags += -s WASM=1 -s ASSERTIONS=1 \
	-s TOTAL_MEMORY=65536000 \
	-s ENVIRONMENT=\"'web,node'\" \
	-s WASM_OBJECT_FILES=0 --llvm-lto 0 \
	-s DISABLE_EXCEPTION_CATCHING=1
javascript-web: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--preload-file lua@/" \
	make -C src js
	@mkdir -p build/web
	@cp -v src/zenroom.js   build/web/
	@cp -v src/zenroom.data build/web/
	@cp -v src/zenroom.wasm build/web/
	@mkdir -p ${website}/js
	@cp -v build/web/* ${website}/js/
	@mkdir -p ${website}/encrypt
	@cp -v build/web/zenroom.data ${website}/encrypt/

javascript-wasm: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-wasm: ldflags += -s ENVIRONMENT=\"'web,node,shell'\" \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s WARN_UNALIGNED=1 \
	-s FILESYSTEM=1 \
	-s ASSERTIONS=1 \
	--no-heap-copy
javascript-wasm: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--embed-file lua@/" \
	make -C src js
	@mkdir -p build/wasm
	@cp -v src/zenroom.js build/wasm/
	@cp -v src/zenroom.wasm build/wasm/

javascript-rn: cflags += -DARCH_JS -D'ARCH=\"JS\"' -D MAX_STRING=128000
javascript-rn: ldflags += -s WASM=0 \
	-s ENVIRONMENT=\"'shell'\" \
	-s MODULARIZE=1 \
	-s LEGACY_VM_SUPPORT=1 \
	-s ASSERTIONS=1 \
	-s EXIT_RUNTIME=1 \
	--memory-init-file 0
javascript-rn: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--embed-file lua@/" \
	make -C src js
	sed -i 's/require("crypto")/require(".\/crypto")/g' src/zenroom.js
	sed -i 's/require("[^\.]/console.log("/g' src/zenroom.js
	sed -i 's/console.warn.bind/console.log.bind/g' src/zenroom.js
	@mkdir -p build/rnjs
	@cp -v src/zenroom.js 	  build/rnjs/

