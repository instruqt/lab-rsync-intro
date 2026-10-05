# Various configuration

local "fileserver_src_dir" {
  value = "/opt/data/vosp_1000/"
}

local "workstation_dst_dir" {
  value = "vosp_1000/"
}

# Do we need to debug the sandbox host?
local "debug_sandbox_host" {
  value = true
}
