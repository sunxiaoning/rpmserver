init:
	@echo "Init env ..."

default: build-repo

# build the project

install-repostore:
	./hack/install.sh repostore

install-reposerver:
	./hack/install.sh reposerver

uninstall-reposerver:
	./hack/uninstall.sh reposerver

install-repoconf:
	./hack/install.sh repoconf

start-reposerver:
	./hack/run.sh start

run-reposerver: install-reposerver install-repoconf start-reposerver

autorun-reposerver: install-repostore run-reposerver

reload-reposerver:
	./hack/run.sh reload

stop-reposerver:
	./hack/run.sh stop