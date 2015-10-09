<#
The following piece of code would get status of a client's process and based on its specification from the client would sent a notification to the end client.
If the client says that say, at 7 AM daily if some of there process do not complete,an email would be sent to them.
The client data would be obtained using distributed SQL from the environment using a stored procedure.
#>

# Database connection that would fetch data from using a stored procedure.

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=DBServer;Database=Database;Integrated Security=True"
$SqlConnection.Open()

[String] $Strsql = "EXEC StoredProcedure;select status from table"
$Sqlcmd = New-Object System.Data.SqlClient.SqlCommand  $Strsql , $SqlConnection

$Stsval = $Sqlcmd.ExecuteReader()

while ($Stsval.read())
{
$sts = $Stsval.Getvalue(0)
}

$SqlConnection.Close()


Write-output  $sts

if ($sts -match "not started yet" -Or $sts -match "in progress") 
{
Send-MailMessage -From from@domain.com -To to@domain.com  -Subject "Process Status of the Client" -body $sts -SmtpServer xx.xx.xx.xx 
}


 

