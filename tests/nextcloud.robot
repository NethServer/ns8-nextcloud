*** Settings ***
Library    SSHLibrary

*** Variables ***
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${SCENARIO}    install
${nc_url}    https://127.0.0.1

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Ping nextcloud
    ${out}  ${err}  ${rc} =    Execute Command    curl -f -k -H "Host: nextcloud.dom.test" https://127.0.0.1
    ...    return_rc=True  return_stdout=True  return_stderr=True
    Should Be Equal As Integers    ${rc}  0

Nextcloud is up to date
    ${out} =    Execute Command    runagent -m ${module_id} occ status --output=json
    &{status} =    Evaluate    json.loads($out)    modules=json
    Should Be True    ${status.installed}
    Should Not Be True    ${status.maintenance}
    Should Not Be True    ${status.needsDbUpgrade}

Read the file of u1
    ${out} =    Execute Command    curl -sk -f -u u1:${u1_password} -H "Host: nextcloud.dom.test" ${nc_url}/remote.php/dav/files/u1/upgrade.txt
    Should Be Equal    ${out}    upgrade-test-${module_id}

*** Test Cases ***
Check if nextcloud is installed correctly
    # The update scenario starts from the NS8 stable release, then upgrades it below
    ${image} =    Set Variable If    '${SCENARIO}' == 'update'    nextcloud    ${IMAGE_URL}
    ${output}  ${rc} =    Execute Command    add-module ${image} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if nextcloud can be configured
    ${out}  ${err}  ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "nextcloud.dom.test", "lets_encrypt": false, "domain": "", "password": "Nethesis,1234", "internal_smarthost": false}'
    ...    return_rc=True  return_stdout=True  return_stderr=True
    Should Be Equal As Integers    ${rc}  0

Check if nextcloud works as expected
    Wait Until Keyword Succeeds    60 times    10 seconds    Ping nextcloud

Create user u1 with a file
    # Nextcloud rejects well-known passwords, and the occ wrapper does not pass the environment
    ${password} =    Evaluate    "Ct-" + secrets.token_hex(8)    modules=secrets
    Set Suite Variable    ${u1_password}    ${password}
    ${rc} =    Execute Command    runagent -m ${module_id} podman exec -e OC_PASS=${u1_password} --user www-data nextcloud-app php ./occ user:add --password-from-env --display-name="First User" u1
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    ${code} =    Execute Command    echo upgrade-test-${module_id} > /tmp/nc-upgrade.txt; curl -sk -o /dev/null -w "\%{http_code}" -u u1:${u1_password} -H "Host: nextcloud.dom.test" -T /tmp/nc-upgrade.txt ${nc_url}/remote.php/dav/files/u1/upgrade.txt
    Should Be Equal    ${code}    201
    Read the file of u1

Update nextcloud to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    ${rc} =    Execute Command
    ...    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check the database migration completed
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    Wait Until Keyword Succeeds    30 times    10 seconds    Nextcloud is up to date

Check the configuration survives the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    ${out} =    Execute Command    api-cli run module/${module_id}/get-configuration
    &{config} =    Evaluate    json.loads($out)    modules=json
    Should Be Equal    ${config.host}    nextcloud.dom.test
    Should Be True    ${config.installed}
    Should Be True    ${config.running}

Check u1 and its file survive the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    Wait Until Keyword Succeeds    60 times    10 seconds    Ping nextcloud
    ${rc} =    Execute Command    runagent -m ${module_id} occ user:info u1
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    Wait Until Keyword Succeeds    10 times    10 seconds    Read the file of u1

Check if nextcloud is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
