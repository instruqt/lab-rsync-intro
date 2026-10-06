#!/usr/bin/env bash

set -euo pipefail

SCRIPT=$(basename "${BASH_SOURCE[0]}")
ERRNO=0


# Constants

# What Instruqt expects the qcow2 image layer media type to be set to
IMG_MEDIA_TYPE="application/vnd.instruqt.vm.disk.v1"
# What Instruqt expects the (empty, for us, but still required) bootstrap
# overlay media type to be set to
IMG_MEDIA_BOOTSTRAP_TYPE="application/vnd.instruqt.vm.bootstrap.v1"
BOOTSTRAP_VERSION_ANNOTATION="vnd.instruqt.vm.bootstrap.version=v1"

# Argument values and defaults
TAG=""		    # -t TAG
REGISTRY=""	    # -r REGISTRY
DEFAULT_REGISTRY="europe-west1-docker.pkg.dev/instruqt-kula/lab-images"	# -r REGISTRY

function do_exit {
    local rc=${1:-0}
    ERRNO="${rc}"
    exit "${rc}"
}

# shellcheck disable=SC2329
function ONEXIT {
    local id="${IMG_DIR:-}"

    if [ "${ERRNO}" == "0" ]; then
	if [ -n "${id}" ]; then
	    rm -rf "${id}"
	fi
    else
	if [ -n "${id}" ]; then
	    echo "Leaving images in ${id}"
	fi
    fi
}

trap ONEXIT EXIT

function help {
    echo "${SCRIPT} - build images for sample lab"
    echo
    echo " -r REGISTRY - Set the registry to use, defaults to"
    echo "               ${DEFAULT_REGISTRY}"
    echo " -t TAG      - Set the image tag to TAG. Optional, defaults to"
    echo "               Unix epoch timestamp"
    echo
}


# Get arguments
while getopts t:r: FLAG; do
    case ${FLAG} in
	t)  # version flag
	    TAG="${OPTARG}"
	    ;;
	r)  # registry flag
	    REGISTRY="${OPTARG}"
	    ;;
	\?) # Unrecognized option
	    echo "Unrecognized option '${OPTARG}'" 1>&2
	    help
	    do_exit 2
	    ;;
    esac
done

# Handle defaults
TAG="${TAG:-$(date +%s)}"			# Default tag is Unix epoch timestamp
REGISTRY="${REGISTRY:-${DEFAULT_REGISTRY}}"

# Make temporary directory for image output - Packer requires that the
# image directory not exist, so create a temp dir and then tell Packer
# to use the 'images' subdir under that.
# 
IMG_DIR="$(mktemp -d)/images"
echo "Images will be output to ${IMG_DIR}"

# Build images
pushd packer
packer build \
    -var "image_output_directory=${IMG_DIR}" \
    . || {
    RC="$?"
    echo "packer build failed" 1>&2;
    do_exit "${RC}";
}
popd

pushd "${IMG_DIR}"
for img in * ; do
    echo "Handling ${REGISTRY}/${img}:${TAG}"
    echo " + Pushing ${REGISTRY}/${img}:${TAG}..."
    qemu-img info "${img}"
    oras push \
	--artifact-type "${IMG_MEDIA_TYPE}" \
	"${REGISTRY}/${img}:${TAG}" \
	"${img}:${IMG_MEDIA_TYPE}"
    
    # Even though we don't need a bootstrap overlay because we
    # embed what the overlay does inside our Packer configuraton,
    # if you don't include this layer you will get an error
    # message

    echo " + Creating blank overlay layer"
    qemu-img create -q -f qcow2 -b "${img}" -F qcow2 "${img}-bootstrap"

    echo " + Attaching bootstrap overlay"
    oras attach \
	--artifact-type "${IMG_MEDIA_BOOTSTRAP_TYPE}" \
	--annotation "${BOOTSTRAP_VERSION_ANNOTATION}" \
	--annotation "org.opencontainers.image.title=instruqt-agent-bootstrap" \
	--annotation \
	"org.opencontainers.image.description=Instruqt agent bootstrap overlay for ${REGISTRY}/${img}:${TAG}" \
	--disable-path-validation \
	"${REGISTRY}/${img}:${TAG}" \
	"${img}-bootstrap:${IMG_MEDIA_BOOTSTRAP_TYPE}"
    echo "DONE."
    echo
done
popd

do_exit "${ERRNO}"
