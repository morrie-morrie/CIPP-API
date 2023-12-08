function Invoke-NudgeMFA {
    <#
    .FUNCTIONALITY
    Internal
    #>
    param($Tenant, $Settings)
    If ($Settings.Remediate) {
        $status = if ($Settings.enable -and $Settings.disable) {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'You cannot both enable and disable the Nudge MFA setting' -sev Error
            Exit
        } elseif ($Settings.enable) { 'enabled' } else { 'disabled' }
        Write-Output $status
        try {
            $body = '{"registrationEnforcement":{"authenticationMethodsRegistrationCampaign":{"snoozeDurationInDays":0,"state":"' + $status + '","excludeTargets":[],"includeTargets":[{"id":"all_users","targetType":"group","targetedAuthenticationMethod":"microsoftAuthenticator","displayName":"All users"}]}}}'
            New-GraphPostRequest -tenantid $tenant -Uri 'https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy' -Type patch -Body $body -ContentType 'application/json'
            Write-LogMessage -API 'Standards' -tenant $tenant -message "$status Authenticator App Nudge" -sev Info
        } catch {
            Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to $status Authenticator App Nudge: $($_.exception.message)" -sev Error
        }
    }
    if ($Settings.Alert) {
        $CurrentInfo = New-GraphGetRequest -Uri 'https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy' -tenantid $Tenant
        if ($CurrentInfo.registrationEnforcement.authenticationMethodsRegistrationCampaign.state -eq 'enabled') {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Authenticator App Nudge is enabled' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Authenticator App Nudge is not enabled' -sev Alert
        }
    }
}