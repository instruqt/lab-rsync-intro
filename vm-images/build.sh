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
UPLOAD="false"	    # -U, defaults to not uploading

function do_exit {
    local rc=${1:-0}
    ERRNO="${rc}"
    exit "${rc}"
}

# shellcheck disable=SC2329
function ONEXIT {
    local id="${IMG_DIR:-}"

    if [ "${UPLOAD}" == "false" ]; then
	if [ -n "${id}" ]; then
	    echo "Leaving images in ${id}"
	else
	    echo "Manual upload requested but IMG_DIR not"
	fi
    else
	if [ "${ERRNO}" == "0" ]; then
	    if [ -n "${id}" ]; then
		# Not uploading, no error, clean up images
		rm -rf "${id}"
	    fi
	else
	    if [ -n "${id}" ]; then
		# Not uploading, but error, so leave images around
		echo "Leaving images in ${id}"
	    fi
	fi
    fi
}

trap ONEXIT EXIT

function help {
    echo "${SCRIPT} - build images for sample lab"
    echo
    echo " -U          - Automatically upload images with tag set by -t to"
    echo "               registry defined by -r. Defaults to off, which"
    echo "               leaves images locally to be manually uploaded."
    echo " -r REGISTRY - Set the registry to use, defaults to"
    echo "               ${DEFAULT_REGISTRY}. Only used if -U is set."
    echo " -t TAG      - Set the image tag to TAG. Optional, defaults to"
    echo "               Unix epoch timestamp, only used if -U is set."
    echo " -h          - Print this help"
    echo
}


# Get arguments
while getopts Ut:r:h FLAG; do
    case ${FLAG} in
	U)  # Upload flag
	    UPLOAD="true"
	    ;;
	t)  # version flag
	    TAG="${OPTARG}"
	    ;;
	r)  # registry flag
	    REGISTRY="${OPTARG}"
	    ;;
	h)  # help
	    help
	    do_exit 0
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
echo
echo "Images will be output to ${IMG_DIR}"
echo

# Build images
pushd packer >/dev/null
packer build \
    -var "image_output_directory=${IMG_DIR}" \
    . || {
    RC="$?"
    echo "packer build failed" 1>&2;
    do_exit "${RC}";
}
popd >/dev/null

pushd "${IMG_DIR}" > /dev/null
if [ "${UPLOAD}" == "false" ]; then
    # Manual upload, remind user
    echo
    echo "***************************************************************************************"
    echo
    echo "Be sure to import these images following the documentation at"
    echo "https://docs.labs.instruqt.com/building-blocks/image-builder/importing-images/"
    echo
fi

for img in * ; do
    if [ "${UPLOAD}" != "true" ]; then
	# User requested manual upload, so remind of image to upload
	echo " - Image: ${IMG_DIR}/${img}"
	continue
    fi

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
popd > /dev/null

if [ "${UPLOAD}" == "false" ]; then
    # Manual upload, remind user
    echo
    echo "***************************************************************************************"
    echo
fi

do_exit "${ERRNO}"
