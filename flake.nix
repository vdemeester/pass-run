{
  description = "Inject secrets from passage into environment variables at runtime";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = self.packages.${system}.passage-run;
          passage-run = pkgs.stdenvNoCC.mkDerivation {
            pname = "passage-run";
            version = "0.1.0";

            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall
              install -Dm755 passage-run $out/bin/passage-run
              wrapProgram $out/bin/passage-run \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.passage ]}
              runHook postInstall
            '';

            meta = {
              description = "Inject secrets from passage into environment variables at runtime";
              homepage = "https://github.com/vdemeester/passage-run";
              license = pkgs.lib.licenses.mit;
              mainProgram = "passage-run";
            };
          };
        }
      );
    };
}
