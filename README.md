# ns8-nextcloud

Start and configure a Nexctloud instance:
- with PHP FPM + nginx as a proxy
- redis caching
- MariaDB database
The module uses [Official Nextcloud image](https://hub.docker.com/_/nextcloud).

## Install

Instantiate the module:
```
add-module nextcloud 1
```

The output of the command will return the instance name.
Output example:
```
{'module_id': 'nextcloud8', 'image_name': 'nextcloud', 'image_url': 'ghcr.io/nethserver/nextcloud:latest'}
```

## Configure

Let's assume that the nextcloud istance is named `nextcloud1`.

Then launch `configure-module`, by setting the following parameters:
- fully qualified domain name for Nextcloud
- let's encrypt option
- LDAP domain (optional)

Example:
```
api-cli run configure-module --agent module/nextcloud1 --data - <<EOF
{
    "host": "nextcloud.nethserver.org",
    "lets_encrypt": true,
    "domain": "ad.nethserver.org"
}
EOF
```

To execute `occ` command inside an instance:
```
ssh nextcloud1@localhost
runagent occ <args>
```

You can customize FPM configuration by changing the file named `zzz_nethserver.conf` inside the state directory.
Example: `/home/nextcloud1/.config/state/zzz_nethserver.conf`.

## Uninstall

To uninstall the instance:

    remove-module --no-preserve nextcloud1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/nextcloud:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
