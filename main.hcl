resource "lab" "rsync-intro" {
  title       = "Rsync Intro"
  description = "An introduction to the basic use of the rsync file-copying tool"

  settings {
    timelimit {
      duration = "15m"
    }

    idle {
      enabled = true
      timeout = "5m"
    }
  }

  layout = resource.layout.default

  content {
    chapter "__default" {
      # Create a lab with no chapters, only pages, by putting
      # in a special __default chapter
      title = "Default"

      page "intro-to-rsync" {
        reference = resource.page.intro-to-rsync
      }

      page "incremental-update" {
        reference = resource.page.incremental-update
      }
    }
  }
}
