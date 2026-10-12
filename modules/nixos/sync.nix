{ ... }:

{
  # Syncthing keeps the task list in step with your phone.
  # Its web interface is at http://127.0.0.1:8384
  services.syncthing = {
    enable = true;
    user = "Vi";
    group = "users";
    dataDir = "/home/Vi";
    configDir = "/home/Vi/.config/syncthing";
    openDefaultPorts = true;
  };
}
