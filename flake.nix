{
  outputs = { self, nixpkgs }: {
    nixosConfigurations.lab-ca-kvm-02 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/lab-ca-kvm-02/configuration.nix ];
    };
  };
}
