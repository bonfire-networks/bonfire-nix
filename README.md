# `bonfire-nix`

A Nix flake providing NixOS modules for [Bonfire](https://bonfirenetworks.org/) provisioning.

## Usage

The `bonfire-nix` flake contains a NixOS module to deploy Bonfire. Assuming you have NixOS with flakes installed on a server, in case you don't you can setup one easily with [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere), the following steps will allow you to have a working Bonfire instance.

### 1. Add the `bonfire-nix` flake to your `flake.nix`

It is sufficient to add `bonfire-nix` to your Flake's inputs and the NixOS module to your machine inputs like this:

```nix
{
  ...

  inputs = {
    ...

    bonfire-nix.url = "github:bonfire-networks/bonfire-nix/main"; # Or a specific tag/commit
  };

  outputs = { self, nixpkgs, bonfire-nix, ... }@inputs: {
      nixosConfigurations.<your-machine> = nixpkgs.lib.nixosSystem {
          ...

          bonfire-nix.nixosModules.bonfire
        ];
      };
    };
}
```

Then run `nix flake lock.`

### 2. Setup SSL certificates

You want to setup SSL certificates provisioning as soon as possible, since everything from now on presupposes HTTPS. To do so on the NixOS, you have to add the `security.acme` module to your `configuration.nix`:

```scheme
security.acme.acceptTerms = true;
security.acme.defaults.email = "youremail@address.org";
```

### 3. Secrets

The Bonfire module is able to load secrets stored as files, so you are free to choose whichever option you prefer to provision and rotate them. One option to provision secrets as files in a Nix aware way is [sops-nix](https://github.com/Mic92/sops-nix). You can refer to [`sops-nix`' tutorial for a more in depth explaination](https://github.com/Mic92/sops-nix/tree/master?tab=readme-ov-file#usage-example).

#### `age` keys

First you need a set of cryptographic keys to encrypt your secrets, in this example [`age`](https://age-encryption.org) will be used. If you already have your `age` keys, skip to the **SOPS secrets** section.

Run the following on server to generate keys for the `root` account:

```shell
~$ sudo -i
Password: 
~# mkdir -p ~/.config/sops/age
~# nix-shell -p age --run 'age-keygen -o /root/.config/sops/age/keys.txt'
...

Public key: age1m3hcq7d9sl3d0uz6ezxvns4f7mjctksmmf5d8tpptmyz30rk9qnscgzfsa
```

You'll need one keypair for each user of the secret so, if you intend to be able to update secrets on a different machine than the one you are installing Bonfire on, make sure to generate a keypair there as well. If you are creating secrets on a PC or a laptop and intend to run Bonfire on a server you SSH into, this is your scenario. Create one keypair for your user on your machine at `$HOME.config/sops/age/keys.txt` with the above command.

Next you need to create a SOPS configuration file, named `.sops.yaml`, in the same directory your `configuration.nix` file is:

```yaml
keys:
    # This is the public key of your laptop/PC
    - &user_yourself_age age1peu96695en0xrlshkd3j3zzd04payh3cx27yjw6r40z8ekemnuesmkrupn
    # This is the public key of the server you are installing Bonfire upon
    - &host_yoursystem age1m3hcq7d9sl3d0uz6ezxvns4f7mjctksmmf5d8tpptmyz30rk9qnscgzfsa

creation_rules:
    - path_regex: .*yoursystem\.yaml$
      key_groups:
          - age:
                - *user_yourself_age
                - *host_yoursystem
```

You are now ready to create the [secrets you need](https://docs.bonfirenetworks.org/deploy.html#secret-keys-for-which-you-should-put-random-secrets).

#### SOPS secrets

In this example the PostgreSQL password secret is being created, but other secrets are created the same way. You can generate a random string with:

```shell
nix-shell -p openssl --run 'openssl rand -base64 32'
v/hSYQHNCJMYW+U8D3m6ADQ+5382jN9iJ69gfImEISY=
```

From the same directory where the `.sops.yaml` and your configuration are stored, run the following command to create a `yoursystem.yaml` file that will store your encrypted secrets. Unencrypted secrets are supposed to never hit the disk, check out `sops-nix` README for more information.

```bash
nix-shell -p sops --run 'sops yoursystem.yaml'
```

Your default editor will pop up. Replace the SOPS example secrets and add the following content to the file:

```yaml
bonfire:
    postrgres_password: v/hSYQHNCJMYW+U8D3m6ADQ+5382jN9iJ69gfImEISY=
```

Save and close the editor. You can now check inside `yoursystem.yaml` and see that the secrets is effectively encrypted.

When all secrets are in your `yoursystem.yaml` file your can add the following to your operating system configuration:

```nix
# This will add yoursystem.yml to the nix store
# You can avoid this by adding a string to the full path instead, i.e.
# sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
sops.defaultSopsFile = ./yoursystem.yaml;

# This will automatically import SSH keys as age keys
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

# This is using an age key that is expected to already be in the filesystem
sops.age.keyFile = "/root/.config/sops/age/keys.txt";

# This will generate a new key if the key specified above does not exist
sops.age.generateKey = false;

# This is the actual specification of the secrets.
# Each element of the option represents
# one key in yoursystem.yaml.  In this case
# it represents:
#
# bonfire:
#      postgres_password:

sops.secrets."bonfire/postgres_password" = {
  mode = "0440";
  group = config.users.users.postgres.group;
};
```

### 4. Bonfire module

The Bonfire module provisions a Bonfire process, a Meilisearch process and a PostgreSQL process. Bonfire and Meilisearch are backed by OCI containers while Postgres is running with Nix built binaries. It is sufficient to add the following to your `configuration.nix`:

```nix
bonfire = {
  # The Bonfire flavor you wish to deploy
  flavor = "social";
  # The version of Bonfire you wish to deploy
  version = "1.0.0-rc.3";
  # A fully qualified domain name you wish to expose Bonfire from
  hostname = "yourdomain.com";
  # The email address you want to send Bonfire emails from
  mail-from = "youremail@address.org";
  # The mail backend you wish to use
  mail-backend = "sendgrid";
  # The paths to the email secrets you setup before
  mail-key = "/run/secrets/bonfire/mail_key";
  meili-master-key = "/run/secrets/bonfire/meili_master_key";
  # The Meilisearch version you intend to use. By default the latest is used
  meilisearch-tag = "v1.14";
};
```

#### 5. Reverse proxy

The last piece to be able to access your instance from the Internet is a reverse proxy. We'll use NGINX but any one should work. To configure NGINX to forward traffic to Bonfire the following must be added to your configuration:

```scheme
security.acme.acceptTerms = true;
security.acme.defaults.email = "youremail@address.org";
services.nginx = {
  enable = true;
  virtualHosts = {
    "yourdomain.org" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4000";
        extraConfig =
          # Taken from https://www.nginx.com/resources/wiki/start/topics/examples/full/
          # Those settings are used when proxies are involved
          "proxy_redirect          off;" +
          "proxy_set_header        Host $host;" +
          "proxy_set_header        X-Real-IP $remote_addr;" +
          "proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;" +
          "proxy_http_version      1.1;" +
          "proxy_cache_bypass      $http_upgrade;" +
          "proxy_set_header        Upgrade $http_upgrade;" +
          "proxy_set_header        Connection \"upgrade\";" +
          "proxy_set_header        X-Forwarded-Proto $scheme;" +
          "proxy_set_header        X-Forwarded-Host  $host;";
      };
    };
  };
};

# Open the HTTP/S ports on the firewall
networking = {
  firewall = {
   enable = true;
   allowedTCPPorts = [ 80 443 ];
   allowedUDPPorts = [];
 };
};

```

Now you can run `nixos-rebuild switch --flake yourflake` and you should be able to visit `yourdomain.org` to access the Bonfire instance.

## Join our community

If you have questions about anything related to Bonfire, you're always welcome to ask our community on [Matrix](https://matrix.to/#/#bonfire-networks:matrix.org), [Slack](https://join.slack.com/t/elixir-lang/shared_invite/zt-2ko4792lz-28XosraCTaYZKOyuZ80hrg), [Elixir Forum](https://elixirforum.com) and the [Fediverse](https://indieweb.social/@bonfire) or send us an email at team@bonfire.cafe.

## Copyright and License

Copyright (c) 2025 Bonfire Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program.  If not, see <https://www.gnu.org/licenses/>.
