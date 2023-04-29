SOURCE:= $(shell test -e src/ && find src -type f -name "*.zig")
DEPS:= $(shell test -e deps/ && find deps -type f -name "*.zig")

policy.wasm: $(SOURCE) $(DEPS) build.zig
	zig build -Drelease-fast
	cp ./zig-out/lib/kw-policy-zig.wasm policy.wasm

annotated-policy.wasm: policy.wasm metadata.yml
	kwctl annotate -m metadata.yml -u README.md -o annotated-policy.wasm policy.wasm

.PHONY: fmt
fmt:
	zig fmt --check src

.PHONY: test
test:
	zig build test

.PHONY: e2e-tests
e2e-tests: annotated-policy.wasm
	bats e2e.bats

.PHONY: clean
clean:
	rm -rf zig-cache zig-out policy.wasm annotated-policy.wasm
