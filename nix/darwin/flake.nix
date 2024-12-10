{
  description = "MacOS nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      # Packages
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages =
        [ pkgs.mkalias
	  pkgs.nano
	  pkgs.tmux
	  pkgs.discord
        ];

      homebrew = {
	enable = true;
	brews = [
	  "mas"
	];
	casks = [
	  "google-chrome"
	];
	masApps = {
	  "Bitwarden" = 1352778147;
	  "Slack" = 803453959;
	  "WhatsApp" = 310633997;
	  "Wireguard" = 1451685025;
	};
	onActivation.cleanup = "zap";
	onActivation.autoUpdate = true;
	onActivation.upgrade = true;
      };

      fonts.packages =
	[ pkgs.jetbrains-mono
	  pkgs.fira-code
	];

      system.defaults = {
	dock.autohide = true;
	dock.autohide-time-modifier = 0.5;
	dock.show-recents = false;
	dock.persistent-apps = [ "/System/Applications/Launchpad.app"
				 "/Applications/Google Chrome.app"				 
				 "/System/Applications/Mail.app"
				 "/System/Applications/Calendar.app"
				 "/System/Applications/Notes.app"
				 "/Applications/WhatsApp.app"
				 "/Applications/Slack.app"
				 "${pkgs.discord}/Applications/Discord.app"
				 "/System/Applications/System Settings.app"
	 ];
	dock.persistent-others = [ "/Users/edson/Downloads" ];
	NSGlobalDomain.AppleInterfaceStyle = "Dark";
	NSGlobalDomain.KeyRepeat = 2;
	controlcenter.BatteryShowPercentage = true;
      };

      system.activationScripts.applications.text = let
  	env = pkgs.buildEnv {
    	name = "system-applications";
    	paths = config.environment.systemPackages;
    	pathsToLink = "/Applications";
      };
    in
      pkgs.lib.mkForce ''
  	# Set up applications.
  	echo "setting up /Applications..." >&2
  	rm -rf /Applications/Nix\ Apps
  	mkdir -p /Applications/Nix\ Apps
  	find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
  	while read -r src; do
    	app_name=$(basename "$src")
    	echo "copying $src" >&2
    	${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
  	done
      '';

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable zsh shell support in nix-darwin.
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [ 
	configuration
	nix-homebrew.darwinModules.nix-homebrew
	{
	  nix-homebrew = {
	    enable = true;
	    # Apple Silicon
	    enableRosetta = true;
	    user = "edson";
	  };
	}
      ];
    };

    # Expose the package set, including overlays, for convenience.
    # darwinPackages = self.darwinConfigurations."macbook".pkgs;
  };
}
