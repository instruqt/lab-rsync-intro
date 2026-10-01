# Test for completion of page.intro-to-rsync
resource "task" "intro-to-rsync" {
  description     = "Complete the intro to rsync"
  success_message = "Complete!"

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
  
  condition "ran_rsync" {
    description = "Rsync was successfully ran"
    
    check {
      script          = "scripts/common/check-ran"
      failure_message = format("The '%s' directory doesn't exist, did you run the `rsync` command?",
                               local.workstation_dst_dir)
    }

    check {
      script          = "scripts/intro-to-rsync/check-correct-options"
      failure_message = "That doesn't quite look right, did you run the rsync command with the correct options?"
    }

    solve {
      script = "scripts/intro-to-rsync/solve"
    }

    cleanup {
      script = "scripts/common/cleanup"
    }
  }
}

# Test for completion of page.incremental-update
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
