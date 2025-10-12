{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.safari.enable = lib.mkEnableOption "sensible Safari configuration";

  config = lib.mkIf config.myDarwin.system.safari.enable {
    # Make safari not suck
    system.defaults.CustomUserPreferences."com.apple.Safari" = {
      # Privacy: don't send search queries to Apple
      # UniversalSearchEnabled = false;
      # SuppressSearchSuggestions = true;
      # Press Tab to highlight each item on a web page
      WebKitTabToLinksPreferenceKey = true;
      ShowFullURLInSmartSearchField = true;
      # Prevent Safari from opening 'safe' files automatically after downloading
      AutoOpenSafeDownloads = false;
      ShowFavoritesBar = false;
      IncludeInternalDebugMenu = true;
      InclueDevelopMenu = true;
      WebKitDeveloperExtrasEnabledPreferenceKey = true;
      WebContinuousSpellCheckingEnabled = true;
      WebAutomaticSpellingCorrectionEnabled = false;
      AutoFillFromAddressBook = false;
      AutoFillCreditCardData = false;
      AutoFillMiscellaneousForms = false;
      WarnAboutFraudulentWebsites = true;
      WebKitJavaEnabled = false;
      WebKitJavaScriptCanOpenWindowsAutomatically = false;
    };
  };
}
