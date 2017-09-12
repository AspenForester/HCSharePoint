<#
  .Synopsis
    Deletes the specified record from a sharepoint list
  .DESCRIPTION
    Remove-SPListItem takes a sharepoint site and the name of a list and deletes the record specified by the ID parameter.
    The deletes are committed once all IDs are processed.
  .EXAMPLE
    Remove-SPListItem -uri "https://team.hennepin.us/vex" -list "testlist" -id 14
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER id
    Sharepoint record id to delete.
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
        $id
    )
    Begin
    {
        # Load the required DLLs
        #Add-SPCSOM
        
        $ClientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)
        $list = $ClientContext.Web.Lists.GetByTitle($listname)
    }
    Process
    {
        $ListItem = $list.getItemById($id)
        Write-Verbose ("Removing record {0}" -f $id)
        if ($PSCmdlet.ShouldProcess($id, 'Remove Item'))
        {
            $ListItem.DeleteObject()
        }
    }
    End
    {
        $ClientContext.ExecuteQuery()
    }
}