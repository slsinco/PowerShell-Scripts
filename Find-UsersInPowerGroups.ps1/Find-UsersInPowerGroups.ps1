Function GetPrivilegedGroupsWithPaths()
{
	Param($allDomains, $emptyPaths)
	$sids = GetRootPowerGroupSIDs $allDomains
	$GroupPaths = @{}
	#$mostpaths = 0
	$sids | % {
		$GroupObjects = GetNestedGroupsBySID $_
		$GroupObjects | %{
			$go = $_
			if(-not $GroupPaths.ContainsKey($go.DN))
			{
				$GroupPaths[$go.DN] = @()
			}
			if(-not ($GroupPaths[$go.DN]).Contains(@($go.Path)))
			{
				$GroupPaths[$go.DN] += ,@($go.Path)#construct new array as a member, don't collapse elements into parent array

			}
		}
	}
	$GroupPaths.Keys | % {
		[pscustomobject] @{
			"DN" = $_
			"Name" = ([adsi] "LDAP://$_").Properties.Item("sAMAccountName").Value
			"Paths" = @($GroupPaths[$_])
		}
	}
}



Function PrintUsersInPowerGroups()
{
	$service = "Any compromise of a system running a service with this account can take over your whole domain! Run as a lower privilege user if possible. Restrict allowed logon types and locations using group policy User Rights Assignment."
	$easa = "Enterprise and Schema admins are Universal groups. Remove users (except built-in Administrator) from these groups, and add temporarily when needed for tasks."
	$old = "This group is an old holdover from Server 2000. Maybe Remove members and make them OU admins as needed."
	$advice = @{
		"Domain Admins"="For humans: The less accounts with this privilege the better.`nFor service accounts: $service"
		"Administrators"="Except for the built-in Administrator account, no users should be directly in this group!`nFor service accounts: $service"
		"Enterprise Admins" = $easa
		"Schema Admins" = $easa
		"Account Operators" = $old
		"Backup Operators" = $old
		"Server Operators" = $old
	}
	
	$groups = GetPrivilegedGroupsWithPaths
	$sanmap = @{}
	$dnmap = @{}
	$groups | % {
		$sanmap[$_.Name] = $_
		$dnmap[$_.DN] = $_
	}

	$utitle = "Users in this group" #since this property name prints out
	
	$currentGroup = $null
	GetUsersInGroups $groups | Sort-Object -Property @("Groupname", "Username") | %{
		$item = $_
		if($currentGroup -ne $item.Groupname)
		{
			Write-Output ""
			write-output ""
			$currentGroup = $item.Groupname
			H1 $item.Groupname
			$adv = "$($advice[$item.Groupname])`n"
			if($adv -eq "`n")
			{
				$adv = "This group is a member of:`n"
				# "Paths" is a list of lists
				$sanmap[$item.Groupname].Paths | % {
					$adv += "{ """
					$sans = @($_ | %{$dnmap[$_].Name})
					$adv +=  $sans -join """ -> """
					$adv += """ }:`n"
					$adv += $advice[$sans[-1]]
					$adv += "`n`n"
				}
			}
			H2 "Advice"
			write-output (word-wrap $adv) #includes its own newlines

			H2 "Users in this group"
		}
		write-output "$($item.Username) $(?: {$item.Disabled} {'(Disabled: delete this user?)'} {''})"
	}
}

PrintUsersInPowerGroups