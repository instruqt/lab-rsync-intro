resource "page" "intro-to-rsync" {
  title = "Introduction to Rsync"
  file  = "instructions/intro-to-rsync.md"

  activities = {
    intro-to-rsync = resource.task.intro-to-rsync
  }
}

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
