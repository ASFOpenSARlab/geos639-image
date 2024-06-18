all: build run

build:
	 bash ./helper_scripts/build.sh 2>&1 | tee log

run:
	docker run -it --init -p 8888:8888 geos639-container:latest
