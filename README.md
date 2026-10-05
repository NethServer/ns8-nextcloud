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

## Single sign-on (OIDC)

Work in progress, see NethServer/dev#8080. Nextcloud can log users in
with an OpenID Connect provider, like the NS8 idp module, next to the
password login form. The provider is not discovered automatically yet:
the settings are written manually in the `oidc.env` file of the module
state directory. At every start of the `nextcloud-app` service the
`setup-oidc` step installs and configures the `user_oidc` app, or
disables it if the settings are missing.

| Variable | Required | Description |
|---|---|---|
| `OIDC_ISSUER` | yes | Issuer URL of the realm, for example `https://sso.example.org/realms/dp.example.org` |
| `OIDC_CLIENT_ID` | yes | OIDC client ID |
| `OIDC_CLIENT_SECRET` | yes | OIDC client secret |
| `OIDC_PROVIDER_NAME` | no | Provider name in the login button, default `Single Sign-On` |
| `OIDC_LOGIN_REDIRECT` | no | `1` redirects the login page straight to the provider, without the password form |

OIDC logins map to the existing LDAP accounts of the user domain, and
no other account is created:

- the `ldap_uuid` claim of the token is the Nextcloud user ID, like the
  user IDs of `user_ldap`: `entryUUID` on OpenLDAP, the uppercase
  `objectGUID` on Active Directory;
- the LDAP login filter also matches the UUID, so a user never seen by
  Nextcloud can log in at the first try.

The client of the provider needs the redirect URIs
`https://<host>/apps/user_oidc/code` and
`https://<host>/index.php/apps/user_oidc/code`.

For example, with the idp module:

```
api-cli run module/idp1/register-client --data '{"domain": "dp.example.org", "module_id": "nextcloud1", "redirect_uris": ["https://cloud.example.org/apps/user_oidc/code", "https://cloud.example.org/index.php/apps/user_oidc/code"], "post_logout_redirect_uris": ["https://cloud.example.org/"], "web_origins": ["https://cloud.example.org"]}'
runagent -m nextcloud1 sh -c 'umask 077; cat > oidc.env' <<'EOF'
OIDC_ISSUER=https://sso.example.org/realms/dp.example.org
OIDC_CLIENT_ID=nextcloud1
OIDC_CLIENT_SECRET=<client_secret from register-client>
EOF
runagent -m nextcloud1 systemctl --user restart nextcloud-app.service
```

After the logout from the provider, the browser returns to the Nextcloud
home page, `https://<host>/`: register it in `post_logout_redirect_uris`,
otherwise the provider refuses the logout redirect.

The `user_oidc` app is installed from the Nextcloud app store, so the
first configuration needs Internet access. A failure of `setup-oidc` is
logged and does not stop Nextcloud. The file is included in the module
backup. Password logins keep working, for example for WebDAV clients.

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
