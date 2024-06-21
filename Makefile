all: build run

build:
	 bash ./helper_scripts/build.sh 2>&1 | tee log

run:
	docker run -it --init --rm -p 8888:8888 -v $(CURDIR)/jupyter-data:/home/jovyan geos639-container:latest
