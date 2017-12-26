function Get-HPSM9ChangeRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Uri,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $ChangeId,

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
            $ChangeKeysType = New-Object ($NameSpace + ".ChangeKeysType")
            $ChangeInstanceType = New-Object ($NameSpace + ".ChangeInstanceType")
            $ChangeModelType = New-Object ($NameSpace + ".ChangeModelType")
            $ChangeModelType.instance = $ChangeInstanceType
            $ChangeModelType.keys = $ChangeKeysType
            $Change = New-Object ($NameSpace + ".StringType")
            $Change.Value = $ChangeId
            $ChangeKeysType.ChangeID = $Change
            $RetrieveChangeRequest = New-Object ($NameSpace + ".RetrieveChangeRequest")
            $RetrieveChangeRequest.model = $ChangeModelType
            $Result = $WebService.RetrieveChange($RetrieveChangeRequest)
            if ($Result.Status -eq "Success") {
                [pscustomobject]@{
                    Impact            = $Result.model.instance.Impact.Value
                    ResordId          = $Result.model.instance.recordid
                    Service           = $Result.model.instance.Service.Value
                    Category          = $Result.model.instance.header.Category.Value
                    AssignmentGroup   = $Result.model.instance.header.AssignmentGroup.Value
                    ConfigurationItem = $Result.model.instance.middle.ConfigurationItem.Value
                    Status            = $Result.model.instance.header.Status.Value
                    InitiatedBy       = $Result.model.instance.header.InitiatedBy.Value
                }
            }
            else {
                $Message = "{0} with the message {1}" -f ($Result.Status, $Result.message)
                Write-Warning -Message $Message
            }
        }
        catch {
            $_.Exception.ErrorRecord
        }
    }
    
    end {
    }
}