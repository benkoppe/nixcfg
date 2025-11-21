{
  myTerranix.profiles.proxmox-lxc = {
    enable = true;

    disk.size = 50;

    cpu.cores = 10;

    memory = {
      dedicated = 32768;
      swap = 4096;
    };
  };
}
