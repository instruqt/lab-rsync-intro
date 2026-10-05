# Small shared network
resource "network" "main" {
  subnet = "172.20.0.0/25"
}

resource "vm" "workstation" {
  
  depends_on = [resource.exec.sandbox-debug]
 
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

  # Check for existence of startup script "DONE" file
  health_check {
    timeout = "30s"

    exec {
      exit_code = 0
      script    = <<-EOT
        #!/bin/bash
        until $(stat /root/.state/setup-workstation.DONE >/dev/null 2>&1); do
          sleep 1
        done
        exit 0
      EOT
    }
  }
}

resource "vm" "fileserver" {

  depends_on = [resource.exec.sandbox-debug]

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

  # Check for existence of startup script "DONE" file
  health_check {
    timeout = "30s"

    exec {
      exit_code = 0
      script    = <<-EOT
        #!/bin/bash
        until $(stat /root/.state/setup-fileserver.DONE >/dev/null 2>&1); do
          sleep 1
        done
        exit 0
      EOT
    }
  }
}

resource "exec" "sandbox-debug" {
  run_as {
    user  = "root"
    group = "root"
  }

  environment = {
    IGGYS_SSH_PRIVATE_KEY_BASE64 = resource.secret.ssh_key.value
  }

  # We do this, instead of using the `disabled` field for this resource
  # because when local.debug_sandbox_host is true we want this to run
  # *AND* we want the VMs above to wait for it to happen, but when we
  # set that to false I'm not sure we can depend on a resource which
  # is disabled. So we decide which script to run, the one where
  # debug_sandbox_host is false is a no-op. Wastes some time, but
  # :shrug:

  script = local.debug_sandbox_host ? "./scripts/sandbox-debug" : "./scripts/sandbox-debug-null"
}
