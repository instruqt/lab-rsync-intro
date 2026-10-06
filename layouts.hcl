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

    tab "workstation-root" {
      disabled  = local.in_development ? false : true
      title     = "Workstation ROOT (For Dev Only)"
      target    = resource.terminal.workstation-root
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
