{
  lib,
  buildNpmPackage,
}:
buildNpmPackage {
  pname = "pi-agent-deps";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-THFReEVuQVnkqOQJPdDb0qm+GkWFYiDFS46ec52obMU=";
  npmDepsFetcherVersion = 2;

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r node_modules $out/node_modules
    runHook postInstall
  '';
}
