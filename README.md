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
- `internal_smarthost` (required): `true` to manage email sending from
  the Nextcloud admin panel, `false` to apply the cluster smarthost
  settings every time the `nextcloud-app` service starts. With `false`
  and no cluster smarthost configured, the module removes the SMTP
  server settings entered in the Nextcloud admin panel.

Example:
```
api-cli run module/nextcloud1/configure-module --data - <<EOF
{
    "host": "nextcloud.nethserver.org",
    "lets_encrypt": true,
    "domain": "ad.nethserver.org",
    "password": "Nethesis,1234",
    "internal_smarthost": false
}
EOF
```

To execute `occ` command inside an instance:
```
runagent -m nextcloud1 occ <args>
```

You can customize FPM configuration by changing the file named `zzz_nethserver.conf` inside the state directory.
Example:

```
runagent -m nextcloud1 vi zzz_nethserver.conf
```

## Two-factor authentication (TOTP)

See the [Nextcloud two-factor documentation](https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/two_factor-auth.html) for all options.

### Enforce TOTP for all users

```
runagent -m nextcloud1 occ twofactorauth:enforce --on
```
Output:
```
Two-factor authentication is enforced for all users
```

Users without a second factor must set up TOTP at their next login.
To limit it to some groups, use `--group <group>` or `--exclude <group>`.

Check the current policy:
```
runagent -m nextcloud1 occ twofactorauth:enforce
```

Stop enforcing it:
```
runagent -m nextcloud1 occ twofactorauth:enforce --off
```
Output:
```
Two-factor authentication is not enforced
```

### Find the user ID

LDAP users have an internal Nextcloud ID (a UUID), not their login name:
```
runagent -m nextcloud1 occ user:list
```
Output:
```
  - admin: admin
  - 0A1B2C3D-0000-4000-8000-000000000001: John Doe (john.doe)
  - 0A1B2C3D-0000-4000-8000-000000000002: Jane Smith (jane.smith)
```

Here the ID of `john.doe` is `0A1B2C3D-0000-4000-8000-000000000001`.

### Disable TOTP for a user

Use this when a user lost their authenticator app:
```
runagent -m nextcloud1 occ twofactorauth:disable 0A1B2C3D-0000-4000-8000-000000000001 totp
```
Output:
```
Two-factor provider totp disabled for user 0A1B2C3D-0000-4000-8000-000000000001.
```

This also deletes the TOTP secret, so the old authenticator entry stops working.
The user then enrolls again with a new QR code:
- if TOTP is enforced, Nextcloud asks to set it up right after the password at the next login
- otherwise, the user enables TOTP in Personal settings > Security

Backup codes do not count as a second factor, so they do not bypass this step.
Do not use `occ twofactorauth:cleanup totp` here: it removes TOTP data for all users.

### Check the enrollment

```
runagent -m nextcloud1 occ twofactorauth:state 0A1B2C3D-0000-4000-8000-000000000001
```

After the reset, before the user enrolls again:
```
Two-factor authentication is not enabled for user 0A1B2C3D-0000-4000-8000-000000000001

Disabled providers:
- backup_codes
- totp
```

Once the user has enrolled, `totp` is listed as enabled:
```
Two-factor authentication is enabled for user 0A1B2C3D-0000-4000-8000-000000000001

Enabled providers:
- totp
Disabled providers:
- backup_codes
```

## Specific ldap mail field for Samba AD

You can change the mail field used by Nextcloud with an environment variable. The default LDAP mail field is `userPrincipalName`, which corresponds to the AD domain name and not the user's email address.
By adding `LDAP_MAIL_ATTRIBUTE` your users wil be able to login with :
 - `sAMAccountName`: eg `john`
 - `userPrincipalName`: eg `john@ad.domain.com`
 - `mail`: eg `john@domain.com`


`runagent -m nextcloud1`
`vim environment`
add : `LDAP_MAIL_ATTRIBUTE=mail`
`systemctl --user restart nextcloud`

## DB-fix script

Nextcloud requires manual database fixes that cannot be automated during upgrade, as operations may take a long time with large amounts of data.
In such cases, the `nextcloud-db-optimize` command can be run manually to optimize the Nextcloud database outside production hours.

    runagent -m nextcloud1 nextcloud-db-optimize

## Uninstall

To uninstall the instance:

    remove-module --no-preserve nextcloud1

## Running tests locally

This module uses the NS8 standard testing infrastructure. For instructions on how to run the test suite locally, refer to the [Running tests locally](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally) section of the ns8-github-actions repository.

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
