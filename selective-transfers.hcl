# Page 3 - Selective Transfers

resource "page" "selective-transfers" {
  title = "Selective Transfers"
  file  = "instructions/selective-transfers.md"

  variables = {
    WORKSTATION_DST_DIR = local.workstation_dst_dir
    FILESERVER_SRC_DIR  = local.fileserver_src_dir
  }

  activities = {
    selective-transfers = resource.task.selective-transfers
  }
}

resource "task" "selective-transfers" {
  description     = "Verify selective transfers"
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

  condition "did_selective" {
    description = "Did a successful selective transfer"

    check {
      script          = "scripts/common/check-ran"
      failure_message = format("The '%s' directory doesn't exist, did you run the `rsync` command?",
                               local.workstation_dst_dir)
    }

    check {
      script          = "scripts/selective-transfer/check-selective-transfer"
      failure_message = "That doesn't quite look right, did you run the rsync command with the correct options?"
    }

    solve {
      script = "scripts/selective-transfer/solve"
    }
  }
}

