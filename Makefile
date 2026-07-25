WASM := plugin.wasm
NDP := navirpc.ndp

build:
	cd plugin && GOOS=wasip1 GOARCH=wasm go build -buildmode=c-shared -o ../$(WASM) .

package: build
	rm -f $(NDP)
	python3 -c "import zipfile; z=zipfile.ZipFile('$(NDP)','w',zipfile.ZIP_DEFLATED); z.write('$(WASM)','plugin.wasm'); z.write('manifest.json','manifest.json'); z.close()"

test:
	go test ./internal/...

setup:
	@# git has one hooks slot and whoever writes it last wins, ask who is here
	@# rather than grabbing it. probe the path the hooks resolve, never PATH,
	@# which needs a login profile containers dont run
	@if [ -x "$$HOME/.local/bin/vox-engine" ]; then \
		git config vox.projectHooks .githooks; \
		git config vox.enabled true; \
		if [ "$$(git config --local --get core.hooksPath)" = ".githooks" ]; then \
			git config --unset core.hooksPath; \
		fi; \
	else \
		git config core.hooksPath .githooks; \
	fi

hygiene:
	@stray=$$(find . -name '*.go' -not -path './internal/*' -not -path './plugin/*' -not -path './.git/*'); \
	if [ -n "$$stray" ]; then echo "go files outside internal/ and plugin/: $$stray" >&2; exit 1; fi
	@bins=$$(git ls-files '*.wasm' '*.ndp'); \
	if [ -n "$$bins" ]; then echo "tracked binaries: $$bins" >&2; exit 1; fi

clean:
	rm -f $(WASM) $(NDP)

.PHONY: build package test setup hygiene clean
