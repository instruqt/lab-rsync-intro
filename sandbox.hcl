resource "secret" "ssh_key" {
  reference = "IGGYS_SSH_PRIVATE_KEY_BASE64"
}

# Small shared network
resource "network" "main" {
  subnet = "172.20.0.0/25"
}

resource "vm" "workstation" {
  config {
    arch = "x86_64"
  }

  image {
    name     = "${variable.instruqt_team_slug}/sgl-rsync-workstation:v1"
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
    name     = "${variable.instruqt_team_slug}/sgl-rsync-fileserver:v1"
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
