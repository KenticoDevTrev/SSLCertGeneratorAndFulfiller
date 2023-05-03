$certs = Get-ChildItem Cert:\LocalMachine\My
foreach($cert in $certs) {
$certSubject = $cert.Subject.Replace('CN=', '')
& ((Split-Path $MyInvocation.InvocationName)+ "\New-CertificateSigningRequest.ps1") -SAN $certSubject -CN $certSubject -O "COMPANYHERE" -OU IT -L "CITYHERE" -S STATECODEHERE -C US
}