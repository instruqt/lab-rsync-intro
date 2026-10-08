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
