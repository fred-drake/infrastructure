resource "proxmox_vm_qemu" "foobar" {
  name        = "foobar"
  target_node = "medivh"
  vmid        = 412
  onboot      = true
  cores       = 2
  sockets     = 2
  memory      = 4096
  clone       = "nixos-template"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = "64G"
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = "9a:42:47:f5:7e:e1"
  }
}
