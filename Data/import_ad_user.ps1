
$ADUsers = Import-csv .\ADUsers.csv

#Loop through each row containing user details in the CSV file 
foreach ($User in $ADUsers)
{
	$Username 	= $User.username
	$Password 	= $User.password
	$Firstname 	= $User.firstname
	$Lastname 	= $User.lastname
	$OU 		= $User.ou #This field refers to the OU the user account is to be created in


    $checkaduser = dsquery user -samid $Username
    if ($checkaduser -like "*DC=MCKINSEY,DC=local")
    {
        Write-Warning "A user account with username $Username already exist in Active Directory."
    }
	else
	{
        dsadd user `
            $OU `
            -samid "$Username" `
            -upn "$Username@MCKINSEY.local" `
            -fn "$Firstname" `
            -ln "$Lastname" `
            -display "$Username" `
            -disabled no `
            -pwd "$Password" `
            -mustchpwd no
    }
}