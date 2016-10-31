## Azure - Get Cost Details From EA Subscriptions
Detailed breakdown of daily resource, daily average, and month to date burnrate.

#### Requirements

* DaysToGoBack           - The days back you wish to use as a starting date, Default is 0 (Today even though the report is likely not contain todays data the script will use the last date in the file as the default starting date).

* enrollmentNumber       - Your EA Enrollment Number

* accesskey              - Your access key

* DailyDetails           - If you put in this switch you will get a detailed resource spend on the $DaysToGoBack date.

* SMTPSendEmail           - Your access key

* SMTPServer              - Setup for O365 smtp.office365.com

* SMTPAutherizedUser      - User that is sending the email

* SMTPAuthorizedPassword  - Password for the user that is sending the email 

* SMTPSendToUsers         - User or Group who should recieve the email


#### Examples
* Example0: This would show you the basic details for the most current day in the report

* Example0: .\ea.ps1 -AccessKey "1001001" -EnrollmentNumber "asdfefiujifh3298ru3298uecj437c8293749jjfc4987rfmuw98c7c298r739cn234r"

* Example1: If today was 10/20/2016 its most likely the most current day in the report is 10/19/2016 and thus the report would show you 10/14/2016 and a detailed resource usage due to "-dailydetails" being used 

* Example1: .\ea.ps1 -EnrollmentNumber 'your enrollment number' -DaysToGoBack 5 -SMTPSendEmail -SMTPServer smtp.office365.com -SMTPAutherizedUser william.lee@spr.com -SMTPAuthorizedPassword password -SMTPSendToUsers william.lee@spr.com -AccessKey 'e123fasdfasdfafrawesdv3'