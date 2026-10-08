# Page 2 - Incremental Updates

resource "page" "incremental-update" {
  title = "Incremental Update"
  file  = "instructions/incremental-update.md"

  variables = {
    WORKSTATION_DST_DIR = local.workstation_dst_dir
    FILESERVER_SRC_DIR  = local.fileserver_src_dir
  }

  activities = {
    incremental-update = resource.task.incremental-update
  }
}

resource "task" "incremental-update" {
  description     = "Verify incremental update"
  success_message = "Success!"

  config {
    target             = resource.vm.workstation
    user               = "iggy"
    group              = "iggy"
    working_directory  = "/home/iggy"
    timeout            = "30s"
    success_exit_codes = [0]
    failure_exit_codes = [1]

    environment = {
      WORKSTATION_DST_DIR = local.workstation_dst_dir
      FILESERVER_SRC_DIR  = local.fileserver_src_dir
    }
  }

  condition "did_incremental" {
    description = "Did a successful incremental transfer"

    setup {
      script = "scripts/incremental-update/setup"
    }

    check {
      script          = "scripts/common/check-ran"
      failure_message = format("The '%s' directory doesn't exist, did you run the `rsync` command?",
                               local.workstation_dst_dir)
    }

    check {
      script          = "scripts/incremental-update/check-correct-options"
      failure_message = "That doesn't quite look right, did you run the rsync command with the correct options?"
    }

    solve {
      script = "scripts/incremental-update/solve"
    }

    cleanup {
      script = "scripts/common/cleanup"
    }
  }
}
