#cloud-config
users:
  - name: root
    lock_passwd: false
    ssh_authorized_keys:
      - ${ssh_public_key}

ssh_pwauth: false
disable_root: false
