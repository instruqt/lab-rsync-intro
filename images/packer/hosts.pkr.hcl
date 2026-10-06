# Copyright (C) 2026, Instruqt. All Rights Reserved.

packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

# Based roughly on https://github.com/homestak-iac/packer/blob/master/templates/debian-12/template.pkr.hcl

variable "ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/id_ed25519_packer"
  description = "Path to SSH private key for Packer to use while building VMs"
}

variable "ssh_public_key_file" {
  type        = string
  default     = ""
  description = "Public key file corresponding to the private key in var.ssh_private_key_file"
}

variable "image_output_directory" {
  type        = string
  default     = "./images"
  description = "Directory in which to place created image, must not exist"
}

locals {
  ssh_public_key   = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : file("${var.ssh_private_key_file}.pub")
}

source "qemu" "workstation" {
  iso_url         = "https://cloud.debian.org/images/cloud/bookworm/20260909-2596/debian-12-generic-amd64-20260909-2596.qcow2"
  iso_checksum    = "file:https://cloud.debian.org/images/cloud/bookworm/20260909-2596/SHA512SUMS"
  iso_target_path = ".cache/debian-12-generic-amd64-20260909-2596.qcow2"
  disk_image      = true

  output_directory = var.image_output_directory
  vm_name          = "sgl-rsync-workstation"
  format           = "qcow2"


  memory               = 2048
  cpus                 = 2
  disk_size            = "10G"    # Instruqt provided images are set with minimum size of 10G so
                                  # we know VMs have enough space to do stuff, so follow that here
  disk_compression     = true
  net_device           = "e1000"
  machine_type         = "q35"
  communicator         = "ssh"
  ssh_username         = "root"
  ssh_private_key_file = var.ssh_private_key_file

  cd_content = {
    "meta-data" = file("./cloud-init/meta-data")
    "user-data" = templatefile("./cloud-init/user-data.pkr.tpl", {
      ssh_public_key = local.ssh_public_key
    })
  }
  cd_label = "cidata"

  headless         = true
  boot_wait        = "60s"
  shutdown_command = "/sbin/shutdown -P now"
  qemuargs = [
    ["-serial", "mon:stdio"],
  ]
}

source "qemu" "fileserver" {
  iso_url         = "https://cloud.debian.org/images/cloud/bookworm/20260909-2596/debian-12-generic-amd64-20260909-2596.qcow2"
  iso_checksum    = "file:https://cloud.debian.org/images/cloud/bookworm/20260909-2596/SHA512SUMS"
  iso_target_path = ".cache/debian-12-generic-amd64-20260909-2596.qcow2"
  disk_image      = true

  output_directory = var.image_output_directory
  vm_name          = "sgl-rsync-fileserver"
  format           = "qcow2"


  memory               = 2048
  cpus                 = 2
  disk_size            = "10G"    # Instruqt provided images are set with minimum size of 10G so
                                  # we know VMs have enough space to do stuff, so follow that here
  disk_compression     = true
  net_device           = "e1000"
  machine_type         = "q35"
  communicator         = "ssh"
  ssh_username         = "root"
  ssh_private_key_file = var.ssh_private_key_file

  cd_content = {
    "meta-data" = file("./cloud-init/meta-data")
    "user-data" = templatefile("./cloud-init/user-data.pkr.tpl", {
      ssh_public_key = local.ssh_public_key
    })
  }
  cd_label = "cidata"

  headless         = true
  boot_wait        = "60s"
  shutdown_command = "/sbin/shutdown -P now"
  qemuargs = [
    ["-serial", "mon:stdio"],
  ]
}

build {

  source "sources.qemu.workstation" {
    name = "workstation"
  }

  source "sources.qemu.fileserver" {
    name = "fileserver"
  }

  provisioner "file" {
    source      = "assets/vosp_1000.tgz"
    destination = "/tmp/vosp_1000.tgz"
  }

  provisioner "file" {
    source      = "scripts/instruqt-agent.service"
    destination = "/tmp/instruqt-agent.service"
  }

  provisioner "shell" {
    scripts = [
      "scripts/baseline-software",
      "scripts/users-and-groups",
      "scripts/example-data",
      "scripts/instruqt-agent"
    ]

    env = {
      DESTINATION_HOST = source.name
    }
  }
}

