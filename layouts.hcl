resource "layout" "default" {
  column {
    width = "70%"

    tab "workstation-terminal" {
      title     = "Workstation"
      target    = resource.terminal.workstation
      closeable = false
    }

    tab "rsync-man-page" {
      title     = "rsync docs"
      target    = resource.virtual_browser.rsync-docs
      closeable = false
    }
  }

  column {
    width = "30%"

    instructions {
      title = "Assignment"
    }
  }
}

# Workstation terminal
resource "terminal" "workstation" {
  target            = resource.vm.workstation
  user              = "iggy"
  group             = "iggy"
  shell             = "/bin/bash"
  working_directory = "/home/iggy"
}

resource "virtual_browser" "rsync-docs" {
  url = "https://download.samba.org/pub/rsync/rsync.1"
}
