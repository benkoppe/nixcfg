{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "herdr-automatic-rename";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: _type: baseNameOf path != "target";
  };
  cargoLock.lockFile = ./Cargo.lock;

  # Herdr expects the manifest at the plugin root and resolves commands from it.
  postInstall = ''
    cp herdr-plugin.toml $out/
  '';

  meta = {
    description = "Automatic Herdr tab names and workspace/agent jump indexes";
    license = lib.licenses.mit;
    mainProgram = "herdr-automatic-rename";
  };
}
