<#
  .Synopsis
    Deletes the specified record from a sharepoint list
  .DESCRIPTION
    Remove-SPListItem takes a sharepoint site and the name of a list and deletes the record specified by the ID parameter.
    The deletes are committed once all IDs are processed.
  .EXAMPLE
    Remove-SPListItem -uri "https://team.hennepin.us/vex" -list "testlist" -id 14

    Removes the list item with ID 14 from the list.
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER id
    Sharepoint record id to delete.
  .PARAMETER Credential
    Credential to authenticate to the SharePoint server.  
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
function Remove-SPListItem
{
    
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "High")]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]
        $uri,
        # Param2 help description
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]
        $listname,
        #record ID
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 2)]
        [int]
        $id,

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
                if ($PSBoundParameters['Credential'])
                {
                    $ConnectParam = @{
                        Credentials = $Credential
                    }
                }
                else
                {
                    $ConnectParam = @{
                        CurrentCredentials = $true
                    }
                }
                
                $Connection = Connect-PnPOnline -ReturnConnection -Url $uri -UseAdfs:$UseADFS -ErrorAction Stop
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
        $Lists = Get-PnPList
        # Case Sensitive List Name
        $CSList = ($Lists | Where-Object Title -like $listname).Title

        Write-Verbose ("Removing record {0}" -f $id)
        Remove-PnPListItem -List $CSList -Identity $id 
        
    }
    End
    {
    }
}