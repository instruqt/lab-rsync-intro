# The documentation at https://docs.labs.instruqt.com/reference/types/variable/#system-variables
# says we don't need this, but the lab does not validate either with `instruqt lab validate` or
# in the platform Web UI if we don't have it

variable "instruqt_team_slug" {
  type        = string
  description = "Reserved: slug of the team running this session, provided by the platform"
}
