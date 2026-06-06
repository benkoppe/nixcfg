{
  flake.modules.hjem.vesktop =
    { pkgs, lib, ... }:
    let
      themes = {
        # "my-theme" = ''
        #   :root {
        #     --background-primary: #000;
        #   }
        # '';
      };
    in
    {
      packages = [
        (pkgs.vesktop.override {
          withSystemVencord = true;
        })
      ];

      xdg.config.files = {
        # vesktop settings
        "vesktop/settings.json" = {
          generator = lib.generators.toJSON { };
          value = { };
        };

        # vencord settings
        "vesktop/settings/settings.json" = {
          generator = lib.generators.toJSON { };
          value = {
            autoUpdate = true;
            autoUpdateNotification = true;
            notifyAboutUpdates = true;

            plugins = {
              CommandsAPI.enabled = true;
              MessageAccessoriesAPI.enabled = true;
              MessageEventsAPI.enabled = true;
              UserSettingsAPI.enabled = true;

              AccountPanelServerProfile = {
                enabled = true;
                prioritizeServerProfile = false;
              };

              ClearURLs.enabled = true;
              CopyEmojiMarkdown.enabled = true;
              CopyFileContents.enabled = true;
              CopyStickerLinks.enabled = true;
              CopyUserURLs.enabled = true;
              CrashHandler.enabled = true;

              FakeNitro = {
                enabled = true;
                enableEmojiBypass = true;
                emojiSize = 48;
                transformEmojis = true;
                enableStickerBypass = true;
                stickerSize = 160;
                transformStickers = true;
                transformCompoundSentence = false;
                enableStreamQualityBypass = true;
                useHyperLinks = true;
                hyperLinkText = "{{NAME}}";
                disableEmbedPermissionCheck = false;
              };

              FixImagesQuality.enabled = true;
              FixYoutubeEmbeds.enabled = true;
              FullSearchContext.enabled = true;
              FullUserInChatbox.enabled = true;
              GifPaste.enabled = true;

              ValidReply.enabled = true;
              ValidUser.enabled = true;

              VencordToolbox = {
                enabled = true;
                showPluginMenu = true;
              };

              VolumeBooster.enabled = true;
              WebKeybinds.enabled = true;
              WebScreenShareFixes.enabled = true;

              BadgeAPI.enabled = true;

              NoTrack = {
                enabled = true;
                disableAnalytics = true;
              };

              Settings = {
                enabled = true;
                settingsLocation = "aboveNitro";
                includeVencordInfoWhenCopying = true;
              };

              ConcatenatedComponentExtractor.enabled = true;
              DisableDeepLinks.enabled = true;
              SupportHelper.enabled = true;
              WebContextMenus.enabled = true;
            };
          };
        };

        "vesktop/settings/quickCss.css".text = "";
      }
      // lib.mapAttrs' (
        name: value:
        lib.nameValuePair "vesktop/themes/${name}.css" {
          text = value;
        }
      ) themes;
    };
}
