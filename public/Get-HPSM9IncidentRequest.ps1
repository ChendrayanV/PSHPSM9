function Get-HPSM9IncidentRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Uri,
    
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $IncidentId,
    
        [Parameter()]
        [System.Management.Automation.CredentialAttribute()]
        [pscredential]
        $Credential
    )
        
    begin {
    }
        
    process {
        try {
            $WebService = New-WebServiceProxy -uri $Uri -ErrorAction Stop
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $WebService.Credentials = [System.Net.NetworkCredential]::new($Credential.UserName, $Credential.Password)
            }
            else {
                $WebService.UseDefaultCredentials = $true
            }
            $NameSpace = $WebService.GetType().NameSpace
            $IncidentKeysType = New-Object ($NameSpace + ".IncidentKeysType")
            $IncidentInstanceType = New-Object ($NameSpace + ".IncidentInstanceType")
            $IncidentModelType = New-Object ($NameSpace + ".IncidentModelType")
            $IncidentModelType.instance = $IncidentInstanceType
            $IncidentModelType.keys = $IncidentKeysType
            $Incident = New-Object ($NameSpace + ".StringType") 
            $Incident.Value = $IncidentId
            $IncidentKeysType.IncidentID = $Incident
            $RetrieveIncidentRequest = New-Object ($NameSpace + ".RetrieveIncidentRequest")
            $RetrieveIncidentRequest.model = $IncidentModelType
            $Result = $WebService.RetrieveIncident($RetrieveIncidentRequest)
            if ($Result.Status -eq 'SUCCESS') {
                [pscustomobject]@{
                    IncidentId      = $Result.model.instance.IncidentID.Value
                    ContactGUID     = $Result.model.instance.ContactGUID.Value
                    AssignmentGroup = $Result.model.instance.AssignmentGroup.Value
                    OpenTime        = $Result.model.instance.OpenTime.Value 
                    ClosedTime      = $Result.model.instance.ClosedTime.Value
                    Status          = $Result.model.instance.Status.Value
                    TimeToClose     = if ($Result.model.instance.Status.Value -eq "Closed") {
                        $Difference = New-TimeSpan -End $Result.model.instance.ClosedTime.Value -Start $Result.model.instance.OpenTime.Value 
                        "{0}:{1}:{2}:{3}" -f ($Difference.Days, $Difference.Hours, $Difference.Minutes, $Difference.Seconds)
                    }
                }
            }
            else {
                $Message = "{0} with the message {1}" -f ($Result.Status, $Result.message)
                Write-Warning -Message $Message
            }
            $WebService.Dispose()
        }
        catch {
            $_.Exception.ErrorRecord 
        }
    }
        
    end {
    }
}