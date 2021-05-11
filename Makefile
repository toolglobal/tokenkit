ifeq ($(mode),debug)
	LDFLAGS="-X 'main.BUILD_TIME=`date`' -X 'main.GO_VERSION=`go version`' -X main.GIT_HASH=`git rev-parse HEAD`"
else
	LDFLAGS="-s -w -X 'main.BUILD_TIME=`date`' -X 'main.GO_VERSION=`go version`' -X main.GIT_HASH=`git rev-parse HEAD`"
endif

.PHONY: build
build:
	export GOPROXY="https://goproxy.io,direct"
	mkdir -p ./build && rm -r ./build
	go build -ldflags ${LDFLAGS} -o build/tokenkit *.go
	cp README.md build
clean:
	rm -rf ./build


