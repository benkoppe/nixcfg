{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
}:

let
  version = "0.21.1";

  platform =
    {
      x86_64-linux = "linux-x64";
      aarch64-linux = "linux-arm64";
      x86_64-darwin = "darwin-x64";
      aarch64-darwin = "darwin-arm64";
    }
    .${stdenv.hostPlatform.system};

  hashes = {
    linux-x64 = "sha256-J6TicUU4FJ8aPKQY/tgYSVVDSAwX36YQMrBz9v9DaP8=";
    linux-arm64 = "sha256-MCFhVvkx6rtJA60OkQDRSJPuOM7EmENuBz8GP/Uakno=";
    darwin-x64 = "sha256-rwFTNIlWsoLpW8mkdb1kQH+u4D0ufTY3wKderZ/pMbA=";
    darwin-arm64 = "sha256-ibSF9UU42tIRzV8eLiloYMw66kM620eF7tM12+JTd68=";
  };
in
stdenv.mkDerivation {
  pname = "plannotator";
  inherit version;

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-${platform}";
    hash = hashes.${platform};
  };

  dontUnpack = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    zlib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/plannotator"
    runHook postInstall
  '';

  meta = {
    description = "Annotate and review coding agent plans and code diffs visually";
    homepage = "https://github.com/backnotprop/plannotator";
    license = lib.licenses.mit; # verify upstream license if you care
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "plannotator";
  };
}
