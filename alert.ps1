#Connect-AzAccount -Tenant '5da5daac-394a-438d-bb8d-001373a8f4e6'
#Connect-AzAccount -Tenant 'eed64c3b-3ad5-491d-a318-61e641e952a2' ###WSDev
##Import-Module AzureAD
#Connect-AzureAD -TenantId '5da5daac-394a-438d-bb8d-001373a8f4e6'
$apps = Get-AzADApplication
$dateFrom = (Get-Date).ToUniversalTime()
$dateTo = $dateFrom.AddDays(7)

foreach($app in $apps){
    $creds = (Get-AzAdAppCredential -ObjectId $app.ObjectId)
    if($creds){ 
        foreach($cred in $creds){
            [pscustomobject]$cred
            $cred.EndDate = [datetime]::ParseExact($cred.EndDate,'d/MM/yyyy h:mm:ss tt',$null).ToString('yyyyMMdd.hhmmss')
        }
        $secrets = $creds | Group-Object -Property Type | Select-Object `
        @{n='Type';e={$_.Group | Select-Object -Expand Type -First 1}},  `
        @{n='EndDate';e={($_.Group | Measure-Object EndDate -Maximum).Maximum}} 
        foreach($secret in $secrets){
            $dateCheck = [datetime]::ParseExact($secret.EndDate.ToString().PadRight(15,'0'),'yyyyMMdd.hhmmss',$null)
            if ($dateCheck -le $dateTo -and $dateCheck -ge $dateFrom ){
                $owners = Get-MgApplicationOwner -ApplicationId 
                if($owners){
                    ##email owners
                    Send-MailMessage -From 
                }else{
                    ### Prep Json Payload
                    $link  = New-Object System.Collections.ArrayList 
                    $alertJson = @{
                        payload = @{
                            summary = "Azure App Registration Expiry"
                            source = "azure-automation-runbooks"
                            severity = "info"
                            component = $secret.Type
                        }
                        custom_details = @{
                            details = $secret.Type + " for " + $app.DisplayName + "will expire" + $secret.EndDate
                        }
                        routing_key = "R02H4KIBLRRRC335FN2CYDNCX1LJ24G8"
                        event_action = "trigger"
                        client = "[Woodside] - Azure"
                        client_url = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Credentials/appId/"+$app.ApplicationId +"/isMSAApp/"
                    }
                    $alertJson.Add("link",$link)
                    write-host 'Converting JSON'
                    $json = $alertJson | Convertto-JSON
                    write-host 'Invoking API'
                    #Invoke-RestMethod -Uri "https://events.pagerduty.com/v2/enqueue" -Method POST -Body $json 
                }
            }
        }
    }
}



