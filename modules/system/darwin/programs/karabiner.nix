{ lib, ... }:
let
  allBasic = map (x: x // { type = "basic"; });

  cancelBehaviorConditions = [
    {
      type = "frontmost_application_unless";
      bundle_identifiers = [
        "^com\\.moonlight-stream\\.Moonlight$"
      ];
    }
  ];

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
          conditions = cancelBehaviorConditions;
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
          conditions = cancelBehaviorConditions;
        }
      ];
    }
  ];
in
{
  flake.modules.darwin.karabiner = {
    homebrew.casks = [
      {
        name = "karabiner-elements";
        greedy = true;
      }
    ];
  };

  flake.modules.hjem.karabiner = {
    xdg.config.files."karabiner/karabiner.json" = {
      generator = lib.generators.toJSON { };
      value = {
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
    };
  };
}
