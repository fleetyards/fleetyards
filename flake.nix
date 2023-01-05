{
  description = "FleetYards Fleetyards backend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    devenv.url = "github:cachix/devenv";
  };

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, devenv, ... }@inputs:
    let
      systems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f:
        builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        }) systems);

      version = "${nixpkgs.lib.substring 0 8 self.lastModifiedDate}-${
          self.shortRev or "dirty"
        }";

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
          config = {
            allowUnfreePredicate = pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [ "elasticsearch" ];
          };
        });
    in {
      overlays.fleet = final: prev: {
        fleet_yards_env = final.callPackage ({ bundlerEnv, ruby_3_0 }:
          bundlerEnv {
            name = "fleet-yards-env";
            ruby = ruby_3_0;
            gemdir = self;
          }) { };

        fleet_yards_update = final.callPackage
          ({ runCommandNoCC, substituteAll, bundix, fleet_yards_env }:
            let
              update = substituteAll {
                name = "update";
                src = ./scripts/update.sh;
                bundix = "${bundix}/bin/bundix";
                bundler = "${fleet_yards_env.bundler}/bin/bundler";
              };
            in runCommandNoCC "update" { } ''
              mkdir -p $out/bin
              cp ${update} $out/bin/update
              chmod +x $out/bin/update
            '') { };

        #fleet_yards = final.callPackage ({ ...}:
        #let
        #in 
        #) {};
      };
      overlays.default = self.overlays.fleet;

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) fleet_yards_env fleet_yards_update;
        #default = self.packages.${system}.ex_fleet_yards;
      });

      legacyPackages = forAllSystems (system: nixpkgsFor.${system});

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                packages = [
                  pkgs.fleet_yards_env
                  pkgs.fleet_yards_env.wrappedRuby
                  pkgs.fleet_yards_update
                ];

                #languages.ruby.enable = true;
                languages.ruby.package = pkgs.ruby_3_0;
                languages.c.enable = true;
                enterShell = ''
                  mkdir -p $APP_DIR/tmp/pids
                '';
              }
              {
                services.postgres.enable = true;
                services.postgres.initdbArgs = [ "-U fleetyards_dev" ];
                services.postgres.initialDatabases = [
                  { name = "fleetyards_dev"; }
                  { name = "fleetyards_test"; }
                ];

                services.redis.enable = true;

                services.elasticsearch = {
                  enable = true;
                  cluster_name = "fleetyards-development-cluster";
                };

                # TODO: minio
              }
              ({ config, ... }: {
                env.DATABASE_HOST = config.env.PGHOST;
                env.DATABASE_USER = "fleetyards_dev";
                env.APP_DIR = "${config.env.DEVENV_STATE}/fleetyards";

                process.implementation = "hivemind";
                scripts.devenv-up.exec = ''
                  ${config.procfileScript}
                '';
              })
            ];
          };
        });

      checks = forAllSystems
        (system: { devenv_ci = self.devShells.${system}.default.ci; });
    };

  nixConfig = {
    extra-substituters = [ "https://fleetbot.cachix.org" ];
    extra-trusted-public-keys =
      [ "fleetbot.cachix.org-1:LCc89Bys++LoaCDgLuO47dcIoSFlRlPvXchGkr5LJLc=" ];
  };
}
