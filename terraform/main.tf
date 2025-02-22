# resource "proxmox_vm_qemu" "foobar" {
#  name        = "foobar"
#  target_node = "medivh"
#  vmid        = 412
#  onboot      = true
#  cores       = 2
#  sockets     = 2
#  memory      = 4096
#  clone       = "nixos-template"
#
#  disks {
#    scsi {
#      scsi0 {
#        disk {
#          size    = "64G"
#          storage = "local-lvm"
#        }
#      }
#    }
#  }
#
#  network {
#    model   = "virtio"
#    bridge  = "vmbr0"
#    macaddr = "9a:42:47:f5:7e:e1"
#  }
#}

resource "hyperv_network_switch" "bridge" {
  name        = "regular"
  switch_type = "External"
}

resource "hyperv_vhd" "web_server_g2_vhd" {
  path = "c:\\Temp\\web_server_g2.vhdx" #Needs to be absolute path
  size = 10737418240                    #10GB
}

resource "hyperv_machine_instance" "foo" {
  name                                    = "WebServer"
  generation                              = 2
  automatic_critical_error_action         = "Pause"
  automatic_critical_error_action_timeout = 30
  automatic_start_action                  = "StartIfRunning"
  automatic_start_delay                   = 0
  automatic_stop_action                   = "Save"
  checkpoint_type                         = "Production"
  guest_controlled_cache_types            = false
  high_memory_mapped_io_space             = 4294967296
  lock_on_disconnect                      = "Off"
  low_memory_mapped_io_space              = 134217728
  memory_maximum_bytes                    = 4294967296
  memory_minimum_bytes                    = 4294967296
  memory_startup_bytes                    = 4294967296
  notes                                   = ""
  processor_count                         = 16
  smart_paging_file_path                  = "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
  snapshot_file_location                  = "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
  #dynamic_memory                         = false
  static_memory = true
  state         = "Running"

  # Configure firmware
  vm_firmware {
    enable_secure_boot = "Off"
    #secure_boot_template            = ""
    preferred_network_boot_protocol = "IPv4"
    console_mode                    = "None"
    pause_after_boot_failure        = "Off"
    boot_order {
      boot_type           = "DVDDrive"
      controller_number   = "1"
      controller_location = "1"
      path                = "c:/Users/fredd/Downloads/nixos-minimal-24.11.714063.fecfeb863283-x86_64-linux.iso"
    }
  }

  # Configure processor
  vm_processor {
    compatibility_for_migration_enabled               = false
    compatibility_for_older_operating_systems_enabled = false
    hw_thread_count_per_core                          = 0
    maximum                                           = 100
    reserve                                           = 0
    relative_weight                                   = 100
    maximum_count_per_numa_node                       = 0
    maximum_count_per_numa_socket                     = 0
    enable_host_resource_protection                   = false
    expose_virtualization_extensions                  = false
  }

  # Configure integration services
  integration_services = {
    "Guest Service Interface" = false
    "Heartbeat"               = true
    "Key-Value Pair Exchange" = true
    "Shutdown"                = true
    "Time Synchronization"    = true
    "VSS"                     = true
  }
  # Create a network adaptor
  network_adaptors {
    name                                       = "wan"
    switch_name                                = "Default"
    management_os                              = false
    is_legacy                                  = false
    dynamic_mac_address                        = true
    static_mac_address                         = ""
    mac_address_spoofing                       = "Off"
    dhcp_guard                                 = "Off"
    router_guard                               = "Off"
    port_mirroring                             = "None"
    ieee_priority_tag                          = "Off"
    vmq_weight                                 = 100
    iov_queue_pairs_requested                  = 1
    iov_interrupt_moderation                   = "Off"
    iov_weight                                 = 100
    ipsec_offload_maximum_security_association = 512
    maximum_bandwidth                          = 0
    minimum_bandwidth_absolute                 = 0
    minimum_bandwidth_weight                   = 0
    mandatory_feature_id                       = []
    resource_pool_name                         = ""
    test_replica_pool_name                     = ""
    test_replica_switch_name                   = ""
    virtual_subnet_id                          = 0
    allow_teaming                              = "On"
    not_monitored_in_cluster                   = false
    storm_limit                                = 0
    dynamic_ip_address_limit                   = 0
    device_naming                              = "Off"
    fix_speed_10g                              = "Off"
    packet_direct_num_procs                    = 0
    packet_direct_moderation_count             = 0
    packet_direct_moderation_interval          = 0
    vrss_enabled                               = true
    vmmq_enabled                               = false
    vmmq_queue_pairs                           = 16
  }
  # Create dvd drive
  dvd_drives {
    controller_number   = "0"
    controller_location = "1"
    path                = "c:/Users/fredd/Downloads/nixos-minimal-24.11.714063.fecfeb863283-x86_64-linux.iso"
  }

  # Create a hard disk drive
  hard_disk_drives {
    controller_type                 = "Scsi"
    controller_number               = "0"
    controller_location             = "0"
    path                            = hyperv_vhd.web_server_g2_vhd.path
    disk_number                     = 4294967295
    resource_pool_name              = "Primordial"
    support_persistent_reservations = false
    maximum_iops                    = 0
    minimum_iops                    = 0
    qos_policy_id                   = "00000000-0000-0000-0000-000000000000"
    override_cache_attributes       = "Default"
  }
}

resource "hyperv_network_switch" "foobar" {
  name                                    = "FooBar"
  notes                                   = ""
  allow_management_os                     = true
  enable_embedded_teaming                 = false
  enable_iov                              = false
  enable_packet_direct                    = false
  minimum_bandwidth_mode                  = "None"
  switch_type                             = "External"
  net_adapter_names                       = ["Ethernet 2"]
  default_flow_minimum_bandwidth_absolute = 0
  default_flow_minimum_bandwidth_weight   = 0
  default_queue_vmmq_enabled              = false
  default_queue_vmmq_queue_pairs          = 16
  default_queue_vrss_enabled              = false
}
