# Using Packer to create Lab images

**NOTE**: This is not officially supported documentation from Instruqt. It
reflects what works as of the commit date, but is not guaranteed to be correct
in the future.

Instruqt officially supports the in-platform [Image Builder](https://docs.labs.instruqt.com/building-blocks/image-builder/overview/),
which has capabilities for both building an image from a small
set of base images, as well as importing a qcow2, VMDK, or raw disk image by
uploading it. Instruqt also supports pulling both container and VM images from an
artifact respository, but that process is not currently, officially, well documented.
This guidance is provided as-is with no guarantee, but may be useful for those
customers who want to automate VM image creation, distribution, and usage.

Background
----------

This directory contains the [Packer](https://developer.hashicorp.com/packer) configuration
used to create the two VMs used in this Lab, along with an auxillary script which takes
the resultant images, adds an overlay image required by the Instruqt platform (more on that
later), and uploads it to a GCP Artifact Registry.

Virtual Machines (VMs) in Instruqt Labs run a `qcow2` formatted disk image, and requires
that the operating system in question have [cloud-init](https://cloud-init.io/) support.
Any Unix- or Linux-based operating system which can meet those requirements would 
probably work. 

These images can be stored in any [Open Container Initiative](https://opencontainers.org/)-compliant
[artifact registry](https://oras.land/docs/concepts/artifact). While the name "Open Container
Initiative" may sound confusing when dealing with VMs, which are manifestly not containers, the
standard has evolved to storing arbitrary files within. The legacy continues on, however; for
example, a GCP [Artifact Registry](https://docs.cloud.google.com/artifact-registry/docs/docker/store-docker-container-images)
which works with Instruqt Labs is configured as a "Docker" format registry, and with GitHub
it is called a [Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

### Image Format

The supported image consists of two components: the base image itself, and an _attachment_
which describes an _overlay_ image.

Internally the overlay image is used with in-platform images (either supported public images,
or those created/uploaded in-platform) to layer on a handful of necessary things: creating a
systemd service unit file for the Instruqt Agent (which is injected via an attached disk added
by cloud-init), zeroing on the `/etc/machine-id` file, and removing any host ssh keys which
may have been created. All of these things we do directly in the Packer configuration here,
since we do not have access to that overlay image. But, the platform still requires the
overlay to exist (it will error on VM creation if it does not), so we create an empty overlay
and add it to the base image as an attachment. 

The base image is created with an _artifact type_ of `application/vnd.instruqt.vm.disk.v1`. The
(empty) overlay image is created with an artifact type of `application/vnd.instruqt.vm.bootstrap.v1`
and the following annotations:

* `vnd.instruqt.vm.bootstrap.version=v1` with no value (required)
* `org.opencontainers.image.title` with the value `instruqt-agent-bootstrap` (required)
* `org.opencontainers.image.description` with the value set to a description (optional)

All of this is handled by the [build.sh](./build.sh) script in this repository.

Pre-requisites
--------------

- [HashiCorp Packer](https://developer.hashicorp.com/packer): used to build the image
- [ORAS](https://oras.land/): CLI-tool to interact with artifact registries
- OCI-compliant "Docker" artifact registry

This repository uses a GCP Artifact Registry, but any OCI-Compliant one which `oras` can
use should work.

### Creating and Uploading to a GCP Artifact Registry

1. Create a GCP ["Docker" Artifact Registry](https://docs.cloud.google.com/artifact-registry/docs/docker/store-docker-container-images)
1. Ensure you have appropriate permissions to upload to that artifact registry
1. Add the following to your `~/.docker/config.json` file:
   ```
   {
     "credHelpers" {
        "europe-west1-docker.pkg.dev": "gcloud"
     }
   }
   ```

   You may use another location, change the `config.json` file as appropriate.
   `europe-west1-docker.pkg.dev` is what Instruqt (at the time of this writing)
   uses for default public images in the platform.

### Using other Artifact Registries

Consult the `oras` documentation.

Creating the Image
------------------

```
build.sh - build images for sample lab

 -r REGISTRY - Set the registry to use, defaults to
               europe-west1-docker.pkg.dev/instruqt-kula/lab-images
 -t TAG      - Set the image tag to TAG. Optional, defaults to
               Unix epoch timestamp
 -h          - Print this help
```

Using the Image in a Lab
------------------------

In the `vm` resource, add the `image` [block](https://docs.labs.instruqt.com/reference/sandbox/compute/vm/#image),
for example:

```
  image {
    name     = "europe-west1-docker.pkg.dev/instruqt-kula/lab-images/sgl-rsync-fileserver:1789680867"
    username = "_json_key_base64"
    password = resource.secret.lab_images_reader_b64.value
  }
```

The `name` field is the full path to the image in the repo, followed by an optional tag.
The `username` and `password` is specific to your Artifact Registry; this example is how
the GCP Artifact Registry does that. Note that we've stored the `password` as a
[secret](https://docs.labs.instruqt.com/building-blocks/secrets/) rather than embedding it
in the code.

### Using with GCP Artifact Registry

1. Follow the instructions for creating a [Service account key](https://docs.cloud.google.com/artifact-registry/docs/docker/authentication#json-key)
1. Give the service account "Artifact Registry Reader" and "Artifactregistry Viewer"
   permissions to your GCP Artifact Registry
2. Set the `username` to `_json_key_base64` and the username to the Base64-encoded
   contents of the JSON format key file GCP provides you when you create the
   service account key
