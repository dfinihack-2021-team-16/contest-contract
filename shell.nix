with import <nixpkgs> {};

pkgs.mkShell {
  name = "contest-contract";
  buildInputs = [
    nodejs
  ];
}
