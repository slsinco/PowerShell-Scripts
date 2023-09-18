$privileged_groups = @('Enterprise Admins', 'Schema Admins', 'Domain Admins', 'Cert Publishers', 'Administrators', 'Account Operators', 'Server Operators', 'Backup Operators', 'Print Operators')

foreach ($group in $privileged_groups){
    echo "--------------------------------------"
    $group
    if ($group) {
	    $group_members = Get-AdGroupMember $group
            foreach ($user in $group_members){
                Get-AdUser $user -Properties LastLogonDate | select UserPrincipalName, LastLogonDate, Enabled
        }
    }
}