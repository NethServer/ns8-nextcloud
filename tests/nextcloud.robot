*** Settings ***
Library    SSHLibrary

*** Test Cases ***
Check if nextcloud is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if nextcloud can be configured
    ${out}  ${err}  ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "nextcloud.test.local", "lets_encrypt": false, "domain": "", "password": "Nethesis,1234"}'
    ...    return_rc=True  return_stdout=True  return_stderr=True
    Should Be Equal As Integers    ${rc}  0

Check if nextcloud works as expected
    Wait Until Keyword Succeeds    20 times    1 seconds    Ping nextcloud

Check if nextcloud is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

*** Keywords ***
Ping nextcloud
    ${out}  ${err}  ${rc} =    Execute Command    curl -f -k -H "Host: nextcloud.test.local" https://127.0.0.1
    ...    return_rc=True  return_stdout=True  return_stderr=True
    Should Be Equal As Integers    ${rc}  0
