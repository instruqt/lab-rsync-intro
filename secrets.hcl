resource "secret" "ssh_key" {
  reference = "IGGYS_SSH_PRIVATE_KEY_BASE64"
}

resource "secret" "lab_images_reader_b64" {
  reference = "LAB_IMAGES_READER_B64"
}
