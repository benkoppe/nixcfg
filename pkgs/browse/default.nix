{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.0.15";

  # From https://anoma.ly/release/browse/cli/stable.json (what opencode.ai/browse/install reads).
  targets = {
    aarch64-darwin = {
      target = "darwin-arm64";
      sha256 = "b0b3a7caa6e0dbc6a21ac689b95cc6aa47e024bf57e72b70d19aa376d8c1d0a7";
    };
    x86_64-darwin = {
      target = "darwin-x64";
      sha256 = "591f5d17578254ce1ce47b255afef4848d601958ca321ad31ca1a47f4dbc9689";
    };
    x86_64-linux = {
      target = "linux-x64";
      sha256 = "282f6e9e8395eb918e6cde5c27f8222fdc6b415b6097b5373c18d07a2f871fa4";
    };
    aarch64-linux = {
      target = "linux-arm64";
      sha256 = "8b631e3db22926f74be63967fa75e71b02a3d9c2cb3985b5dd1639ae5a5efd30";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;
  t = targets.${system} or (throw "browse: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "browse";
  inherit version;

  src = fetchurl {
    url = "https://anoma.ly/release/browse/files/${t.sha256}/opencode-browse-${t.target}-${version}.tgz";
    inherit (t) sha256;
  };

  sourceRoot = "package";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  # A Bun single-file executable: stripping drops the embedded app.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/browse $out/bin/browse
    runHook postInstall
  '';

  meta = {
    description = "Lets agents control your existing Chromium-family browser via the browse extension";
    homepage = "https://opencode.ai/browse";
    license = lib.licenses.mit;
    platforms = builtins.attrNames targets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "browse";
  };
}
