set -ex

BUILD_TAG=$(date +"%F-%H-%M-%S")
COMMIT_HEAD=$(git rev-parse --short HEAD)

IMAGE_NAME="geos639-container"

time docker build -f dockerfile \
    -t $IMAGE_NAME:$BUILD_TAG \
    -t $IMAGE_NAME:latest \
    -t $IMAGE_NAME:$COMMIT_HEAD \
    --target release .
