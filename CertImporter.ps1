# Put .cer files in C:\certs\Responses and rename so it's domain.name.cer (ex "crem.coffee.cer")
# Run below script
# Then upload to highwinds the C:\Exported files

function ProcessCert {
param (
        $DomainName,
        $Password
    )
    
    $securePass = ConvertTo-SecureString -String $Password -AsPlainText -Force
    #import Cert
    $cert = Import-Certificate -FilePath "C:\certs\Responses\$($Domainname).crt" -CertStoreLocation cert:\LocalMachine\My

    # repair the cert private key
    cmd.exe /c "cd C:\Users\Administrator"
    cmd.exe /c "certutil -repairstore my $($cert.SerialNumber.Replace(' ', ''))"


    # retrieve cert again
    $fixedCert = Get-ChildItem -path "Cert:\*$($cert.Thumbprint.Replace(' ', ''))" -Recurse


    # Export
    Export-PfxCertificate -Cert $fixedCert -FilePath "C:\certs\Exported\$($DomainName).pfx" -Password $securePass


    # Run Conversion for files for highwind
    if(!($DomainName -contains "direct.")){
        try {
            $ErrorActionPreference='silentlycontinue'
            $batPath = 'C:\certs\OpenSSL-Win64\convertPFX.bat'
            cmd.exe /c $batPath $DomainName $Password
        } catch {}

    }
   

    # Update bindings
    Foreach ($Binding in Get-WebBinding -Protocol "https" -HostHeader $DomainName) {
        $Binding.AddSslCertificate($fixedCert.GetCertHashString(), "my")
    }
    Foreach ($Binding in Get-WebBinding -Protocol "https" -HostHeader "www.$($DomainName)") {
        $Binding.AddSslCertificate($fixedCert.GetCertHashString(), "my")
    }
}

Get-ChildItem "C:\certs\Responses" -Filter *.crt |
Foreach-Object {
    $password = -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 16 | % {[char]$_})
    # You can use the below line to set a password on the export, otherwise it will use a completely random password which is usually fine.
    #ProcessCert -DomainName $_.BaseName -Password "YourPassword"
    ProcessCert -DomainName $_.BaseName -Password $password
}


