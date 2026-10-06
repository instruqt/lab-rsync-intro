# Small shared network
resource "network" "main" {
  subnet = "172.20.0.0/25"
}

resource "vm" "workstation" {
  config {
    arch = "x86_64"
  }

  image {
    name     = "europe-west1-docker.pkg.dev/instruqt-kula/lab-images/sgl-rsync-workstation:1789680867"
    username = "_json_key_base64"
    password = resource.secret.lab_images_reader_b64.value
  }

  resources {
    cpu    = 2
    memory = 4096
  }

  network {
    id = resource.network.main.meta.id
  }

  startup_script = template_file("./scripts/setup-workstation.tmpl", {
    IGGYS_SSH_PRIVATE_KEY_BASE64 = resource.secret.ssh_key.value
    FILESERVER_SRC_DIR           = local.fileserver_src_dir
    WORKSTATION_DST_DIR          = local.workstation_dst_dir
  })
}

resource "vm" "fileserver" {
  config {
    arch = "x86_64"
  }

  image {
    name     = "europe-west1-docker.pkg.dev/instruqt-kula/lab-images/sgl-rsync-fileserver:1789680867"
    username = "_json_key_base64"
    password = resource.secret.lab_images_reader_b64.value
  }

  resources {
    cpu    = 2
    memory = 4096
  }

  network {
    id = resource.network.main.meta.id
  }

  startup_script = template_file("./scripts/setup-fileserver.tmpl", {
    IGGYS_SSH_PRIVATE_KEY_BASE64 = resource.secret.ssh_key.value
  })

  # SSH listening
  health_check {
    timeout = "30s"

    tcp {
      port = 22
    }
  }
}
