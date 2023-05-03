@echo off
@set PATH=%PATH%;%~dp0bin
@set domainName=%1
@set keyPassword=%2
openssl version -a

%SystemDrive%
cd %UserProfile%

openssl pkcs12 -in "C:\certs\Exported\%domainName%.pfx" -nocerts -out "C:\certs\TempKey\%domainName%.key" -password pass:%keyPassword% -passout pass:%keyPassword%
openssl pkcs12 -in "C:\certs\Exported\%domainName%.pfx" -clcerts -nokeys -out "C:\certs\Exported\%domainName%.crt" -password pass:%keyPassword%
openssl rsa -in "C:\certs\TempKey\%domainName%.key" -out "C:\certs\Exported\%domainName%.key" -passin pass:%keyPassword%
openssl pkcs12 -in "C:\certs\Exported\%domainName%.pfx" -cacerts -nokeys -chain -out "C:\certs\Exported\%domainName%-CACert.cer" -password pass:%keyPassword%

exit /b 0