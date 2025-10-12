{ config, lib, ... }:
let
  allBasic = map (x: x // { type = "basic"; });

  simple_modifications = [ ];

  complex_modifications.rules = [
    {
      description = "Caps lock to esc/control";
      manipulators = allBasic [
        {
          from = {
            key_code = "caps_lock";
            modifiers.optional = [ "any" ];
          };
          to = [ { key_code = "left_control"; } ];
          to_if_alone = [
            {
              key_code = "escape";
              lazy = true;
            }
          ];
        }
      ];
    }

    {
      description = "Left control to hyper";
      manipulators = allBasic [
        {
          from.key_code = "left_control";
          to = [
            {
              key_code = "f19";
              lazy = true;
            }
          ];
        }
      ];
    }
  ];
in
{
  options.myDarwin.programs.karabiner.enable =
    lib.mkEnableOption "enable Karabiner for macOS keyboard customization";

  config = lib.mkIf config.myDarwin.programs.karabiner.enable {
    homebrew.casks = [ "karabiner-elements" ];

    home-manager.sharedModules = [
      {
        xdg.configFile."karabiner/karabiner.json".text = lib.strings.toJSON {
          profiles = [
            {
              inherit complex_modifications;

              name = "Default";
              selected = true;

              virtual_hid_keyboard.keyboard_type_v2 = "ansi";

              devices = [
                {
                  inherit simple_modifications;

                  identifiers.is_keyboard = true;
                }
              ];

              fn_function_keys = [
                {
                  from.key_code = "f3";
                  to = [ { apple_vendor_keyboard_key_code = "launchpad"; } ];
                }
              ];
            }
          ];
        };
      }
    ];
  };
}
