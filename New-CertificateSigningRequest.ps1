<#
.Synopsis
   Create new certificate signing request on Windows platforms
.DESCRIPTION
   Users certreq on Windows platforms to create a certificate
   signing request.
.EXAMPLE
   New-CertificateSigningRequest -SAN mysite.contoso.com,mysitealt.contoso.com -CN mysite.contoso.com -O "Contoso Ltd" -OU IT -L Dallas -S Texas -C US
#>

[CmdletBinding()]
[Alias()]
Param
(
    # Subject Alternative Name(s)
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    [string[]]$SAN,

    # Common Name
    [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=1)]
    [string]$CN,

    # Organisation
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=2)]
    [string]$O,

    # Organisation Unit
    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                Position=3)]
    [string]$OU,

    # Locality (City)
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=4)]
    [string]$L,

    # State
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=5)]
    [string]$S,

    # Country
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=6)]
    [ValidatePattern("[A-Z]{2}")]
    [string]$C,

    # Key length (2048, 3702 or 4096)
    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                Position=6)]
    [ValidatePattern("2048|3072|4096")]
    [string]$keyLength="4096"
)

Begin{

    $ErrorActionPreference = 'Stop'

    if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "Administrator priviliges are required. Please restart this script with elevated rights."
    }

    $settingsInf = "
    [Version] 
    Signature=`"`$Windows NT`$ 
    [NewRequest] 
    KeyLength =  $keyLength
    Exportable = TRUE 
    MachineKeySet = TRUE 
    SMIME = FALSE
    RequestType =  PKCS10 
    ProviderName = `"Microsoft RSA SChannel Cryptographic Provider`" 
    ProviderType =  12
    HashAlgorithm = sha256
    ;Variables
    Subject = `"CN={{CN}},OU={{OU}},O={{O}},L={{L}},S={{S}},C={{C}}`"


    ;Certreq info
    ;http://technet.microsoft.com/en-us/library/dn296456.aspx
    ;CSR Decoder
    ;https://certlogik.com/decoder/
    ;https://ssltools.websecurity.symantec.com/checker/views/csrCheck.jsp
    "
}
Process
{
    
    # create uniq guid to avoid accidents with file name conflicts
    $UID = [guid]::NewGuid()
    
    # build hash table to store file names for settings and csr files
    $Files = @{}
    $Files['settings'] = "$($env:TEMP)\$($UID)-settings.inf";
    $Files['csr'] = "$($env:TEMP)\$($UID)-csr.req"

    # split out SAN values into a string to insert into the 
    # 'settings' file
    $SANString = & {
	    if ($SAN.Count -gt 0) {
		    $varSAN = "2.5.29.17 = `"{text}`"
    "
		    Foreach ($sanItem In $SAN) {
			    $varSAN += "_continue_ = `"dns="+$sanItem+"&`"
    "
		    }
		    return $varSAN
	    }
    }

    # Replace values in setting file and put results in file on disk
    # for certreq to use later
    $settingsInf.Replace("{{CN}}",$CN).Replace("{{O}}",$O).Replace("{{OU}}",$OU).Replace("{{L}}",$L).Replace("{{S}}",$S).Replace("{{C}}",$C).Replace("{{SAN}}",$SANString) | Out-File $Files['settings']

    # complete CSR with certreq
    certreq -new $files['settings'] $files['csr'] | Out-Null

    # Get CSR created with certreq and store in variable
    $CSR = Get-Content $files['csr']

    Set-Content -Path "C:\certs\Requests\{{CN}}.csr".Replace("{{CN}}", $CN) -Value $CSR
	
	# Clean up
    $files.Values | Remove-Item

}
End
{
	
	# Output CSR
    $CSR

}
