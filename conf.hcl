# Various configuration

local "fileserver_src_dir" {
  value = "/opt/data/vosp_1000/"
}

local "workstation_dst_dir" {
  value = "vosp_1000/"
}

# Set this to `true` to enable some
# development helping
local "in_development" {
  value = false
}
