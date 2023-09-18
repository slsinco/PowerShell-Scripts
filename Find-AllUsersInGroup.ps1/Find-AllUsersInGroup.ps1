$groupp=$args[0]

if ($groupp -eq $null) {
    $groupp = read-host -Prompt "Please enter Group Name to Search" 
}

Get-ADGroup -Filter {name -like $groupp} | foreach {
    $currentGroup = $_.Name
    $_ | Get-ADGroupMember | foreach {
        $_ | Get-ADUser | select @{name="Group"; expression={ $currentGroup }}, SamAccountName
    }
 }