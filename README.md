# redis-cli
This is a Linux script that installs the latest `redis-cli` directly from [source](http://download.redis.io/redis-stable.tar.gz).

## Why this script was created

I created this convenience script to install `redis-cli` because I didn't want to install the entire `redis-server` package, and the `redis-cli` version that comes with `redis-tools` bundle provided by Ubuntu repository is very, very old.

Feel free to inspect the source code and report any issues.

## Supported distributions

**IMPORTANT!**

Currently, this project officially supports `Ubuntu 20.04 LTS`, and might need tweaks for other Ubuntu versions or other Unix distributions. 

Feel free to PR modifications to add support for your favorite distribution.

## Usage

Copy and paste the following command on your terminal, then wait while the script does its magic. You will need `sudo` privileges to run it.

*Hint: Hover with your cursor over the code blocks and hit the copy button to copy the command directly to your clipboard.* 

### Copy and paste on your terminal
```shell
curl -sL "https://raw.githubusercontent.com/SecretX33/redis-cli/main/install_redis_cli.sh" | bash
```

Or if you don't have `curl` installed, you can alternatively use `wget` instead.

```shell
wget -qO - "https://raw.githubusercontent.com/SecretX33/redis-cli/main/install_redis_cli.sh" | bash
```

## License

This project is licensed under the [MIT License](LICENSE).
