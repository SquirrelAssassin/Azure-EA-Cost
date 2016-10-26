## Azure - Get Cost Details From EA Subscriptions
Detailed breakdown of daily resource, daily average, and month to date burnrate.

#### Requirements

* [String] $DaysToGoBack      - The days back you wish to use as a starting date, Default is 0 (Today even though the report is likely not contain todays data the script will use the last date in the file as the default starting date).

* [String] $enrollmentNumber  - Your EA Enrollment Number

* [String] $accesskey         - Your access key

* [SWITCH] $DailyDetails      - If you put in this switch you will get a detailed resource spend on the $DaysToGoBack date.

#### Examples
* Example0: This would show you the basic details for the most current day in the report

* Example0: .\ea.ps1 -AccessKey "1001001" -EnrollmentNumber "asdfefiujifh3298ru3298uecj437c8293749jjfc4987rfmuw98c7c298r739cn234r"

* Example1: If today was 10/20/2016 its most likely the most current day in the report is 10/19/2016 and thus the report would show you 10/14/2016 and a detailed resource usage due to "-dailydetails" being used 

* Example1: .\ea.ps1 -dailydetails -$DaysToGoBack 5 -AccessKey "1001001" -EnrollmentNumber "asdfefiujifh3298ru3298uecj437c8293749jjfc4987rfmuw98c7c298r739cn234r"
