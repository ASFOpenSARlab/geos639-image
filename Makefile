all: build run

build:
	 bash ./helper_scripts/build.sh 2>&1 | tee log

run:
	docker run -it --rm -p 8888:8888 -v $(pwd)/virtual_home:/home/jovyan geos639-container:latest
