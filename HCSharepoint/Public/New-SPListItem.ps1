<#
  .Synopsis
    Creates a new record in a Sharepoint list
  .DESCRIPTION
    New-SPListItem takes a sharepoint site and the name of a list, plus an object mapping the field names and values, and creates a new 
    list record in the specified list.
  .EXAMPLE
	$RecordObject = [pscustomobject]@{
		PatchSchedule = "3rdTues2000"
		Environment   = "Development (Sandbox)"
		IsPhysical    = $true
		RAM           = 2
		Storage       = 26
		CPUs          = 2
		Cluster       = "DEVCluster"
		Title         = "hsdiamondvm001"
		}
    New-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist' -record $RecordObject
  .EXAMPLE
    $RecordObject | New-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist'
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER record
    A psobject with properties matching the fields of the list you are adding to.
  .PARAMETER Credential
    Credential to authenticate to the SharePoint server.  
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
function New-SPListItem
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # URI of the Sharepoint site.
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]
        $uri,

        # Name of the List we are adding a record to
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]
        $listname,

        # object with properties correlating to the list's fields, each property's value will be the value of the corresponding field.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 2)]
        [pscustomobject]
        $record,

        # Credentials
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Use ADFS Authentication
        [Switch]
        $UseADFS  
    )
    Begin
    {
        # First we need to connect
        try 
        {
            # There's a chance I might have to deal with mulitple connections...
            # Ensure we are connected to the WebApp specified by $URI
            $Connection = Get-PnPConnection
            if ($Connection.url -ne $uri)
            {
                $ConnectParam = @{
                    URI = $uri
                }
                If ($PSBoundParameters['Credential'])
                {
                    $ConnectParam.Add('Credential',$Credential)

                }
                if ($PSBoundParameters['UseADFS']) 
                {
                    $ConnectParam.Add('UseADFS',$UseADFS)
                }
                Connect-SPWebApp @ConnectParam -ErrorAction Stop
            }
        }
        catch 
        {
            # I might want to handle this differently in the future
            
            Throw $_
        }
    }
    Process
    {
        # Case Sensitive List Name
        $CSList = ($Script:Lists | Where-Object Title -like $listname).Title
        
        # Get the _Case Sensitive_ fields for this list
        #$PSBoundParameters.Remove('Record')
        $CSColumns = Get-SPListField -uri $uri -listname $CSList
        
        $RecordProps = $Record.psobject.properties
        $RecordHash = @{}

        foreach ($RecProp in $RecordProps)
        {
            if ($CSColumns -cnotcontains $RecProp.name)
            {
                Write-Verbose ("Correcting field input: {0}" -f $RecProp.name)
                $CorrectRecordPropertyName = $CSColumns | Where-Object {$_ -eq $RecPropName}
                Write-Verbose ("Corrected Field input: {0} to {1}" -f $RecProp.name,$CorrectRecordPropertyName )
            }
            else {
                $CorrectRecordPropertyName = $RecProp.name
            }
            $RecordHash[$CorrectRecordPropertyName] = $RecProp.Value
        }

        Write-Verbose ("Adding new record to list {0}" -f $listname)
        if ($PSCmdlet.ShouldProcess("List $ListName","Add new record"))
        {
            Add-PnPListItem -List $CSList -Values $RecordHash
        }
    }
    End
    {

    }
}