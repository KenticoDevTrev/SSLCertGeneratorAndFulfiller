# You can use this to generate requests that don't exist yet, just modify the values below to your company, you can do multiple lines and use something like excel to generate these commands
.\New-CertificateSigningRequest.ps1 -SAN "the.website.com" -CN "the.website.com" -O "YourCompanyName" -OU IT -L "YourCity" -S YOURSTATE -C US
