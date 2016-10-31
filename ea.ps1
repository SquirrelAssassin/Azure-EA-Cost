 # Base Info
    Param (
        [Parameter(Mandatory=$false)]
        [int32]$DaysToGoBack=0,
        [Parameter(Mandatory=$true)]
        [int32]$EnrollmentNumber="short number",
        [Parameter(Mandatory=$true)]
        [string]$AccessKey="very long access key",
        [Parameter(Mandatory=$false)]
        [switch]$DailyDetails=$false,
        [Parameter(Mandatory=$false)]
        [switch]$SMTPSendEmail=$false,
        [Parameter(Mandatory=$false)]
        [string]$SMTPServer="smtp.office365.com",
        [Parameter(Mandatory=$false)]
        [string]$SMTPAutherizedUser="",
        [Parameter(Mandatory=$false)]
        [string]$SMTPAuthorizedPassword="",
        [Parameter(Mandatory=$false)]
        [string]$SMTPSendToUsers=""
        )


# Calculate The Two Months To Pull Down
$Date = Get-Date
$Date = $Date.AddDays(-$DaysToGoBack)
$Month = $Date.Year.tostring() + "-" + $Date.Month.tostring()

$ConvertPeriod = [datetime]$Month
$LastMonthComputer = $ConvertPeriod.AddMonths(-1)
$LastMonth = $LastMonthComputer.Year.tostring() + "-" + $LastMonthComputer.Month.tostring()

# Site Access
$BaseUrl = "https://ea.azure.com/rest/"
$AuthHeaders = @{"authorization"="bearer $AccessKey";"api-version"="1.0"}

# Connect To Site And Pull The Months Requested
$Url= $BaseUrl + $EnrollmentNumber + "/usage-report?month=$Month&type=detail"
$Response = Invoke-WebRequest $Url -Headers $AuthHeaders
$Url1= $BaseUrl + $EnrollmentNumber + "/usage-report?month=$LastMonth&type=detail"
$Response1 = Invoke-WebRequest $Url1 -Headers $AuthHeaders

# Split The Response Up Into An Array From A String
$Content = ($Response.Content -split '[\r\n]') |? {$_} 
$Content1 = ($Response1.Content -split '[\r\n]') |? {$_} 

# Convert From CSV To An Object
$CurrentMonthArray = $Content | Where-Object { [regex]::matches($_,",").count -gt 28} | ConvertFrom-Csv
$LastMonthArray = $Content1 | Where-Object { [regex]::matches($_,",").count -gt 28} | ConvertFrom-Csv

# Make the cents readable
$CurrentMonthArray | Foreach {
$rr = [math]::round($_.resourcerate,2); $_.resourcerate = $rr
$ec = [math]::round($_.extendedcost,2); $_.extendedcost = $ec
$ec = [math]::round($_."consumed quantity",2); $_."consumed quantity" = $ec
} 
$LastMonthArray | Foreach {
$rr1 = [math]::round($_.resourcerate,2); $_.resourcerate = $rr1
$ec1 = [math]::round($_.extendedcost,2); $_.extendedcost = $ec1
$ec1 = [math]::round($_."consumed quantity",2); $_."consumed quantity" = $ec1
} 
$TwoMonthArray = $LastMonthArray + $CurrentMonthArray

# Make An Array For All Subscriptions Containing Unique Values Only
$SubscriptionArray = @()
ForEach ($subscription in $CurrentMonthArray) {
  If ($SubscriptionArray -notcontains $Subscription."Account Name")
  {
    $SubscriptionArray += $Subscription."Account Name"
  }
}

# Show Info For A Single Day
## Get Dates
$Body = @()
$LastDateInFile = $TwoMonthArray.date | select -Last 1
$SingleDay = [datetime]$LastDateInFile
$SingleDayYesterday = $SingleDay.AddDays(-1)
$SingleDayFix = Get-Date $SingleDay -Format u
$SingleDayYesterdayFix = Get-Date $SingleDayYesterday -Format u
$SingleDaySplit = $SingleDayFix -split {$_ -eq "-" -or $_ -eq " "}
$SingleDayYesterdaySplit = $SingleDayYesterdayFix -split {$_ -eq "-" -or $_ -eq " "}
$FilterCurrentDay = $SingleDaySplit[1] + "/" + $SingleDaySplit[2] + "/" + $SingleDaySplit[0]
$FilterPreviousDay = $SingleDayYesterdaySplit[1] + "/" + $SingleDayYesterdaySplit[2] + "/" + $SingleDayYesterdaySplit[0]
## Do Work
$CDay = $TwoMonthArray | Where-Object {$_.date -eq $FilterCurrentDay}
$YDay = $TwoMonthArray | Where-Object {$_.date -eq $FilterPreviousDay}
$SingleDayArray = $CDay | Select-Object  "Account Name", Product, date, "Consumed Quantity", ResourceRate, ExtendedCost | Sort-Object -Property "Account Name",ExtendedCost -Descending | ft
$Table = Out-String -InputObject $SingleDayArray
$YDayCost = [math]::round($($YDay | Select-Object -ExpandProperty ExtendedCost | Measure-Object -Sum).sum,2)
$CDayCost = [math]::round($($CDay | Select-Object -ExpandProperty ExtendedCost | Measure-Object -Sum).sum,2)
$DaySum = 1 - ($CDayCost / $YDayCost)
$DayDifference = "{0:P0}" -f $DaySum
### Write Output 
$body += "Daily Average Costs for ($($FilterCurrentDay)):"
ForEach ($UniqueSubscription in $SubscriptionArray) {
    $UniqueAccount = [math]::round($($CDay | Where {$_."Account Name" -eq "$UniqueSubscription"} | Select-Object -ExpandProperty ExtendedCost | Measure-Object -sum).sum,2)
    $body += "$UniqueSubscription = $("$"+$UniqueAccount)"
}
$body += "All Subscriptions ($($FilterPreviousDay)) = $("$" + $YDayCost)"
$body += "All Subscriptions ($($FilterCurrentDay)) = $("$" + $CDayCost)"
if ($DayDifference -like "-*") {
    $body += "Total Spending for ($($FilterCurrentDay)) is $($($DayDifference.trim("-"))) More Than ($($FilterPreviousDay))"
} Else {
    $body += "Total Spending for ($($FilterCurrentDay)) is $($DayDifference) Less Than ($(($FilterPreviousDay)))"
}
$body += " "
#### Create Email Body


# Last 7 Day Average Costs
## Calculate Date Ranges
$BeginningDay = [datetime]$FilterCurrentDay
$GoBack7Days = $BeginningDay.AddDays(-6)
$GoBack8Days = $BeginningDay.AddDays(-7)
$GoBack14Days = $BeginningDay.AddDays(-13)
$FixFormat7Days = Get-Date $GoBack7Days -Format u
$FixFormat8Days = Get-Date $GoBack8Days -Format u
$FixFormat14Days = Get-Date $GoBack14Days -Format u
$SplitFixFormat7Days = $FixFormat7Days -split {$_ -eq "-" -or $_ -eq " "}
$SplitFixFormat8Days = $FixFormat8Days -split {$_ -eq "-" -or $_ -eq " "}
$SplitFixFormat14Days = $FixFormat14Days -split {$_ -eq "-" -or $_ -eq " "}
$Back7Days = $SplitFixFormat7Days[1] + "/" + $SplitFixFormat7Days[2] + "/" + $SplitFixFormat7Days[0]
$Back8Days = $SplitFixFormat8Days[1] + "/" + $SplitFixFormat8Days[2] + "/" + $SplitFixFormat8Days[0]
$Back14Days = $SplitFixFormat14Days[1] + "/" + $SplitFixFormat14Days[2] + "/" + $SplitFixFormat14Days[0]
$SevenDayRange = $TwoMonthArray | Where-Object {$_.date -gt $Back7Days -AND $_.date -lt $FilterCurrentDay}
$FourteenDayRange = $TwoMonthArray | Where-Object {$_.date -gt $Back14Days -AND $_.date -lt $Back8Days}
## Do Work
$SevenDayCost = [math]::round($($SevenDayRange | Select-Object -ExpandProperty ExtendedCost | Measure-Object -Sum).sum,2)
$FourteenDayCost = [math]::round($($FourteenDayRange | Select-Object -ExpandProperty ExtendedCost | Measure-Object -Sum).sum,2)
$WeekSum = 1 - ($SevenDaycost / $FourteenDayCost)
$WeekDifference = "{0:P0}" -f $Weeksum
### Write Output 
$body += "Last 7 Day Average Costs ($($FilterCurrentDay + " - " + $Back7Days)):"
ForEach ($UniqueSubscription in $SubscriptionArray) {
    $UniqueAccount = [math]::round($($SevenDayRange | ? {$_."Account Name" -eq "$UniqueSubscription"} | Select-Object -ExpandProperty ExtendedCost | Measure-Object -sum).sum,2)
    $body += "$UniqueSubscription = $("$"+$UniqueAccount)"
}
$body += "All Subscriptions ($($Back8Days + " - " + $Back14Days)) = $("$"+$FourteenDayCost)"

$body += "All Subscriptions ($($FilterCurrentDay + " - " + $Back7Days)) = $("$"+$SevenDayCost)"

if ($WeekDifference -like "-*") {
    $body += "Total Spending For ($($FilterCurrentDay + " - " + $Back7Days)) is $($WeekDifference.trim("-")) More Than $(($Back8Days - $Back14Days))"
} Else {
    $body += "Total Spending For ($($FilterCurrentDay + " - " + $Back7Days)) is $($WeekDifference) Less Than ($($Back8Days + " - " + $Back14Days))"
}
$body += " "

# Total Monthly Cost
## Do Work
$LastMonthCost = [math]::round($($LastMonthArray | Select-Object -ExpandProperty ExtendedCost | Measure-Object -Sum).sum,2)
$MonthCost = [math]::round($($CurrentMonthArray | Select-Object -ExpandProperty ExtendedCost | Measure-Object -Sum).sum,2)
$MonthSum = 1 - ($MonthCost / $LastMonthCost)
$MonthDifference = "{0:P0}" -f $MonthSum
### Write Output 
$body += "Total Monthly Cost ($($Month)):"
ForEach ($UniqueSubscription in $SubscriptionArray) {
    $UniqueAccount = [math]::round($($CurrentMonthArray | Where {$_."Account Name" -eq "$UniqueSubscription"} | Select-Object -ExpandProperty ExtendedCost | measure-object -sum).sum,2)
    $body += "$UniqueSubscription = $("$"+$UniqueAccount)"
}
$body += "All Subscriptions ($($lastmonth)) = $("$"+$LastMonthCost)"
$body += "All Subscriptions ($($month)) = $("$"+$MonthCost)"
if ($MonthDifference -like "-*") {
    $body += "Total Spending for ($($Month)) Is $($($MonthDifference.trim("-"))) More Than ($($LastMonth))"
} Else {
    $body += "Total Spending for ($($Month)) Is $($MonthDifference) Less Than ($($LastMonth))"
}
$body += " "
$body1 = @()
# Show Table For Resources Used Today
if ($DailyDetails -eq $true) {
$body += "Resource Burn Rate For ($($FilterCurrentDay)):"
$body += " "
$body1 += $($Table.trim())
}
$body
$body1

# email body format

#Below is the email and is set to work with Office 365. 
if ($SMTPSendEmail -eq $true) {
$a = "<style>"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black}"
$a = $a + "TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black}"
$a = $a + "</style>"
$dbody1 = $body | foreach {[pscustomobject]@{'name'=$_}} | ConvertTo-Html -Head $a
$dbody2 = [string]$dbody1
$dbody2 = $dbody2 -replace '<th>\*</th>','<th></th>'
$emaildetails = $CDay  | Sort-Object -Property "Account Name",ExtendedCost -Descending | ConvertTo-Html -Head $a -Property "Account Name", Product, date, "Consumed Quantity", ResourceRate, ExtendedCost
$emaildetailsformat = [string]$emaildetails
$secpasswd = ConvertTo-SecureString $SMTPAuthorizedPassword -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($SMTPAutherizedUser, $secpasswd)
Send-MailMessage -From $SMTPAutherizedUser -To $SMTPSendToUsers -Body ($dbody2 + $emaildetailsformat) -Subject "EA Cost Summary" -SmtpServer $SMTPServer -Credential $mycreds -UseSsl -BodyAsHtml
}
