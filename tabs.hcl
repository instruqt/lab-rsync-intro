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

# For development purposes only
resource "terminal" "workstation-root" {
  target            = resource.vm.workstation
  user              = "root"
  group             = "root"
  shell             = "/bin/bash"
  working_directory = "/root"
}
