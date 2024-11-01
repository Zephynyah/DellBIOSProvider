# Import the helper functions

Import-Module $PSScriptRoot\..\..\Misc\helper.psm1 -Verbose:$false

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Category
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$returnValue = @{
		Category = [System.String]
		MultiCoreSupport = [System.String]
		IntelSpeedStep = [System.String]
		CStates = [System.String]
		IntelTurboBoost = [System.String]
		HyperThreadControl = [System.String]
		Password = [System.String]
		SecurePassword = [System.String]
		PathToKey = [System.String]
	}

	$returnValue
	#>
	
				   # Check if module DellBIOSprovider is already loaded. If not, load it.
   try{
    $bool = Confirm-DellPSDrive -verbose
    }
    catch 
    {
        write-Verbose $_
        $msg = "Get-TargetResource: $($_.Exception.Message)"
        Write-DellEventLog -Message $msg -EventID 1 -EntryType 'Error'
        write-Verbose "Exiting Get-TargetResource"
        return
    }
    if ($bool) {                      
        Write-Verbose "Dell PS-Drive DellSmbios is found."
    }
    else{
        $Message = “Get-TargetResource: Module DellBiosProvider was imported correctly."
        Write-DellEventLog -Message $Message -EventID 2 
    }

    $Get = get-childitem -path @("DellSmbios:\" + $Category)
     # Removing Verbose and Debug from output
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null

  
    $out = @{}   
    $Get | foreach-Object {$out.Add($_.Attribute, $_.CurrentValue)}
    $out.add('Category', $Category )
    $out

}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Category,

		[ValidateSet("RebootBypass","Disabled","ResumeBypass","RebootandResumeBypass")]
		[System.String]
		$PasswordBypass,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$PasswordLock,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$CpuXdSupport,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$CapsuleFirmwareUpdate,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$StrongPassword,

		[ValidateSet("Enabled","Disabled","OnetimeEnable")]
		[System.String]
		$OromKeyboardAccess,
		
		[ValidateSet("Enabled","Disabled","SilentEnable")]
		[System.String]
		$ChasIntrusion,

		[ValidateSet("DoorOpen","DoorClosed","Tripped","TripReset")]
		[System.String]
		$ChassisIntrusionStatus,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$AdminSetupLockout,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$HddProtection,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$IntlPlatformTrust,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$WirelessSwitchChanges,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$GeneralPurposeEncryption,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$MasterPasswordLockout,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$BlockSid,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$PpiBypassForBlockSid,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$SmmSecurityMitigation,

		[System.String]
		$Password,

		[System.String]
		$SecurePassword,

		[System.String]
		$PathToKey
	)

    if (-not(CheckModuleLoaded)) {
        Write-Verbose -Message 'Required module DellBiosProvider does not exist. Exiting.'
        return $true
    }

    $DellPSDrive = get-psdrive -name Dellsmbios
    if ( !$DellPSDrive)
    {
        $Message = "Drive DellSmbios is not found. Exiting."
        Write-Verbose $Message
        Write-DellEventLog -Message $Message -EventID 3 -EntryType "Error"
        return $true
    }
    $attributes_desired = $PSBoundParameters
    $atts = $attributes_desired

    $pathToCategory = $DellPSDrive.Name + ':\' + $atts["Category"]
    
    Dir $pathToCategory -verbose

    $atts.Remove("Verbose") | out-null
    $atts.Remove("Category") | out-null
    $atts.Remove("Debug") | out-null
    $securePwd=$atts["SecurePassword"]
    $passwordSet=$atts["Password"]
    $atts.Remove("Password") | Out-Null
    $atts.Remove("SecurePassword") | Out-Null
    $pathToKey=$atts["PathToKey"]
	if(-Not [string]::IsNullOrEmpty($pathToKey))
	{  
		if(Test-Path $pathToKey)
		{
		$key=Get-Content $pathToKey
		}
		else
		{
		$key=""
		}
	}
    $atts.Remove("PathToKey") | Out-Null
    
    #foreach($a in Import-Csv((Get-DellBIOSEncryptionKey)))
    #{
   # $key+=$a
   # }
    $atts.Keys | foreach-object { 
                   # $atts[$_]
                    $path = $pathToCategory + '\' + $($_)
                    $value = $atts[$_]
		    if(-Not [string]::IsNullOrEmpty($securePwd))
		    {                
			$pasvar=ConvertTo-SecureString $securePwd.ToString() -Key $key
            Set-Item  -path $path -value $value -verbose -ErrorVariable ev -ErrorAction SilentlyContinue -PasswordSecure $pasvar
		    }

		    elseif(-Not [string]::IsNullOrEmpty($passwordSet))
		    {
			Set-Item  -path $path -value $value -verbose -ErrorVariable ev -ErrorAction SilentlyContinue -Password $passwordSet
		    }

		    else
		    {
			Set-Item  -path $path -value $value -verbose -ErrorVariable ev -ErrorAction SilentlyContinue
		    }
                    if ( $ev) { 
                        $cmdline = $ExecutionContext.InvokeCommand.ExpandString($ev.InvocationInfo.Line)
                        $Message = "An error occured in executing " + $cmdline + "`nError message: $($ev.ErrorDetails)"
                        Write-Verbose $Message
                        Write-DellEventLog -Message $Message -EventID 5 -EntryType "Error"
                    }
                    
                 }



}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Category,

		[ValidateSet("RebootBypass","Disabled","ResumeBypass","RebootandResumeBypass")]
		[System.String]
		$PasswordBypass,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$PasswordLock,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$CpuXdSupport,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$CapsuleFirmwareUpdate,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$StrongPassword,

		[ValidateSet("Enabled","Disabled","OnetimeEnable")]
		[System.String]
		$OromKeyboardAccess,
		
		[ValidateSet("Enabled","Disabled","SilentEnable")]
		[System.String]
		$ChasIntrusion,

		[ValidateSet("DoorOpen","DoorClosed","Tripped","TripReset")]
		[System.String]
		$ChassisIntrusionStatus,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$AdminSetupLockout,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$HddProtection,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$IntlPlatformTrust,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$WirelessSwitchChanges,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$GeneralPurposeEncryption,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$MasterPasswordLockout,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$BlockSid,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$PpiBypassForBlockSid,
		
		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$SmmSecurityMitigation,

		[System.String]
		$Password,

		[System.String]
		$SecurePassword,

		[System.String]
		$PathToKey
	)

    $Get = Get-TargetResource $PSBoundParameters['Category'] -verbose

    New-DellEventLog
 
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null
    $PSBoundParameters.Remove("Category") | out-null
    $PSBoundParameters.Remove("Password") | out-null
    $PSBoundParameters.Remove("SecurePassword") | out-null

    $attributes_desired = $PSBoundParameters

    $bool = $true

    foreach ($config_att in  $PSBoundParameters.GetEnumerator())
    {
        if ($Get.ContainsKey($config_att.Key)) {
            $currentvalue = $Get[$config_att.Key]
            $currentvalue_nospace = $currentvalue -replace " ", ""
            if ($config_att.Value -ne $currentvalue_nospace){
                $bool = $false
                $drift  = "`nCurrentValue: $currentvalue_nospace`nDesiredValue: $($config_att.value)"
                $message = "Configuration is drifted in category $Category for $($config_att.Key). $drift"
                write-verbose $message
                Write-DellEventLog -Message $message -EventID 4 -EntryType Warning
            
            }
            else {
                write-Debug "Configuration is same for $config_att."
            }
    }
    else
    {
        $message = "Unsupported attribute $($config_att)"
        Write-Verbose $message
    }
   }
   return $bool

}


Export-ModuleMember -Function *-TargetResource


# SIG # Begin signature block
# MIIu0gYJKoZIhvcNAQcCoIIuwzCCLr8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDPuR4XPRfNhUqJ
# MOfS0ybwaP+BlsEjCp6SytM9lsa5TKCCEwIwggXfMIIEx6ADAgECAhBOQOQ3VO3m
# jAAAAABR05R/MA0GCSqGSIb3DQEBCwUAMIG+MQswCQYDVQQGEwJVUzEWMBQGA1UE
# ChMNRW50cnVzdCwgSW5jLjEoMCYGA1UECxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9s
# ZWdhbC10ZXJtczE5MDcGA1UECxMwKGMpIDIwMDkgRW50cnVzdCwgSW5jLiAtIGZv
# ciBhdXRob3JpemVkIHVzZSBvbmx5MTIwMAYDVQQDEylFbnRydXN0IFJvb3QgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkgLSBHMjAeFw0yMTA1MDcxNTQzNDVaFw0zMDEx
# MDcxNjEzNDVaMGkxCzAJBgNVBAYTAlVTMRYwFAYDVQQKDA1FbnRydXN0LCBJbmMu
# MUIwQAYDVQQDDDlFbnRydXN0IENvZGUgU2lnbmluZyBSb290IENlcnRpZmljYXRp
# b24gQXV0aG9yaXR5IC0gQ1NCUjEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQCngY/3FEW2YkPy2K7TJV5IT1G/xX2fUBw10dZ+YSqUGW0nRqSmGl33VFFq
# gCLGqGZ1TVSDyV5oG6v2W2Swra0gvVTvRmttAudFrnX2joq5Mi6LuHccUk15iF+l
# OhjJUCyXJy2/2gB9Y3/vMuxGh2Pbmp/DWiE2e/mb1cqgbnIs/OHxnnBNCFYVb5Cr
# +0i6udfBgniFZS5/tcnA4hS3NxFBBuKK4Kj25X62eAUBw2DtTwdBLgoTSeOQm3/d
# vfqsv2RR0VybtPVc51z/O5uloBrXfQmywrf/bhy8yH3m6Sv8crMU6UpVEoScRCV1
# HfYq8E+lID1oJethl3wP5bY9867DwRG8G47M4EcwXkIAhnHjWKwGymUfe5SmS1dn
# DH5erXhnW1XjXuvH2OxMbobL89z4n4eqclgSD32m+PhCOTs8LOQyTUmM4OEAwjig
# nPqEPkHcblauxhpb9GdoBQHNG7+uh7ydU/Yu6LZr5JnexU+HWKjSZR7IH9Vybu5Z
# HFc7CXKd18q3kMbNe0WSkUIDTH0/yvKquMIOhvMQn0YupGaGaFpoGHApOBGAYGuK
# Q6NzbOOzazf/5p1nAZKG3y9I0ftQYNVc/iHTAUJj/u9wtBfAj6ju08FLXxLq/f0u
# DodEYOOp9MIYo+P9zgyEIg3zp3jak/PbOM+5LzPG/wc8Xr5F0wIDAQABo4IBKzCC
# AScwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQEwHQYDVR0lBBYw
# FAYIKwYBBQUHAwMGCCsGAQUFBwMIMDsGA1UdIAQ0MDIwMAYEVR0gADAoMCYGCCsG
# AQUFBwIBFhpodHRwOi8vd3d3LmVudHJ1c3QubmV0L3JwYTAzBggrBgEFBQcBAQQn
# MCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLmVudHJ1c3QubmV0MDAGA1UdHwQp
# MCcwJaAjoCGGH2h0dHA6Ly9jcmwuZW50cnVzdC5uZXQvZzJjYS5jcmwwHQYDVR0O
# BBYEFIK61j2Xzp/PceiSN6/9s7VpNVfPMB8GA1UdIwQYMBaAFGpyJnrQHu995ztp
# UdRsjZ+QEmarMA0GCSqGSIb3DQEBCwUAA4IBAQAfXkEEtoNwJFMsVXMdZTrA7LR7
# BJheWTgTCaRZlEJeUL9PbG4lIJCTWEAN9Rm0Yu4kXsIBWBUCHRAJb6jU+5J+Nzg+
# LxR9jx1DNmSzZhNfFMylcfdbIUvGl77clfxwfREc0yHd0CQ5KcX+Chqlz3t57jpv
# 3ty/6RHdFoMI0yyNf02oFHkvBWFSOOtg8xRofcuyiq3AlFzkJg4sit1Gw87kVlHF
# VuOFuE2bRXKLB/GK+0m4X9HyloFdaVIk8Qgj0tYjD+uL136LwZNr+vFie1jpUJuX
# bheIDeHGQ5jXgWG2hZ1H7LGerj8gO0Od2KIc4NR8CMKvdgb4YmZ6tvf6yK81MIIG
# gzCCBGugAwIBAgIQNa+3e500H2r8j4RGqzE1KzANBgkqhkiG9w0BAQ0FADBpMQsw
# CQYDVQQGEwJVUzEWMBQGA1UECgwNRW50cnVzdCwgSW5jLjFCMEAGA1UEAww5RW50
# cnVzdCBDb2RlIFNpZ25pbmcgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAt
# IENTQlIxMB4XDTIxMDUwNzE5MTk1MloXDTQwMTIyOTIzNTkwMFowYzELMAkGA1UE
# BhMCVVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xPDA6BgNVBAMTM0VudHJ1c3Qg
# RXh0ZW5kZWQgVmFsaWRhdGlvbiBDb2RlIFNpZ25pbmcgQ0EgLSBFVkNTMjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL69pznJpX3sXWXx9Cuph9DnrRrF
# GjsYzuGhUY1y+s5YH1y4JEIPRtUxl9BKTeObMMm6l6ic/kU2zyeA53u4bsEkt9+n
# dNyF8qMkWEXMlJQ7AuvEjXxG9VxmguOkwdMfrG4MUyMO1Dr62kLxg1RfNTJW8rV4
# m1cASB6pYWEnDnMDQ7bWcJL71IWaMMaz5ppeS+8dKthmqxZG/wvYD6aJSgJRV0E8
# QThOl8dRMm1njmahXk2fNSKv1Wq3f0BfaDXMafrxBfDqhabqMoXLwcHKg2lFSQbc
# CWy6SWUZjPm3NyeMZJ414+Xs5wegnahyvG+FOiymFk49nM8I5oL1RH0owL2JrWwv
# 3C94eRHXHHBL3Z0ITF4u+o29p91j9n/wUjGEbjrY2VyFRJ5jBmnQhlh4iZuHu1gc
# pChsxv5pCpwerBFgal7JaWUu7UMtafF4tzstNfKqT+If4wFvkEaq1agNBFegtKzj
# bb2dGyiAJ0bH2qpnlfHRh3vHyCXphAyPiTbSvjPhhcAz1aA8GYuvOPLlk4C/xsOr
# e5PEPZ257kV2wNRobzBePLQ2+ddFQuASBoDbpSH85wV6KI20jmB798i1SkesFGaX
# oFppcjFXa1OEzWG6cwcVcDt7AfynP4wtPYeM+wjX5S8Xg36Cq08J8inhflV3ZZQF
# HVnUCt2TfuMUXeK7AgMBAAGjggErMIIBJzASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBTOiU+CUaoVooRiyjEjYdJh+/j+eDAfBgNVHSMEGDAWgBSCutY9l86f
# z3Hokjev/bO1aTVXzzAzBggrBgEFBQcBAQQnMCUwIwYIKwYBBQUHMAGGF2h0dHA6
# Ly9vY3NwLmVudHJ1c3QubmV0MDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwu
# ZW50cnVzdC5uZXQvY3NicjEuY3JsMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzBEBgNVHSAEPTA7MDAGBFUdIAAwKDAmBggrBgEFBQcCARYaaHR0
# cDovL3d3dy5lbnRydXN0Lm5ldC9ycGEwBwYFZ4EMAQMwDQYJKoZIhvcNAQENBQAD
# ggIBAD4AVLgq849mr2EWxFiTZPRBi2RVjRs1M6GbkdirRsqrX7y+fnDk0tcHqJYH
# 14bRVwoI0NB4Tfgq37IE85rh13zwwQB6wUCh34qMt8u0HQFh8piapt24gwXKqSwW
# 3JwtDv6nl+RQqZeVwUsqjFHjxALga3w1TVO8S5QTi1MYFl6mCqe4NMFssess5DF9
# DCzGfOGkVugtdtWyE3XqgwCuAHfGb6k97mMUgVAW/FtPEhkOWw+N6kvOBkyJS64g
# zI5HpnXWZe4vMOhdNI8fgk1cQqbyFExQIJwJonQkXDnYiTKFPK+M5Wqe5gQ6pRP/
# qh3NR0suAgW0ao/rhU+B7wrbfZ8pj6XCP1I4UkGVO7w+W1QwQiMJY95QjYk1Rfqr
# uA+Poq17ehGT8Y8ohHtoeUdq6GQpTR/0HS9tHsiUhjzTWpl6a3yrNfcrOUtPuT8W
# ku8pjI2rrAEazHFEOctAPiASzghw40f+3IDXCADRC2rqIbV5ZhfpaqpW3c0VeLED
# wBStPkcYde0KU0syk83/gLGQ1hPl5EF4Iu1BguUO37DOlSFF5osB0xn39CtVrNlW
# c2MQ4LigbctUlpigmSFRBqqmDDorY8t52kO50hLM3o9VeukJ8+Ka0yXBezaS2uDl
# UmfN4+ZUCqWd1HOj0y9dBmSFA3d/YNjCvHTJlZFot7d+YRl1MIIGlDCCBHygAwIB
# AgIQfLeNpTYQ7xit6Aq3XVt49TANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJV
# UzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjE8MDoGA1UEAxMzRW50cnVzdCBFeHRl
# bmRlZCBWYWxpZGF0aW9uIENvZGUgU2lnbmluZyBDQSAtIEVWQ1MyMB4XDTIzMTEy
# MjE4MTI0NFoXDTI0MTExNzE4MTI0M1owge8xCzAJBgNVBAYTAlVTMQ4wDAYDVQQI
# EwVUZXhhczETMBEGA1UEBxMKUm91bmQgUm9jazETMBEGCysGAQQBgjc8AgEDEwJV
# UzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEfMB0GA1UEChMWRGVsbCBUZWNo
# bm9sb2dpZXMgSW5jLjEdMBsGA1UEDxMUUHJpdmF0ZSBPcmdhbml6YXRpb24xGDAW
# BgNVBAsTD0NsaWVudCBTb2Z0d2FyZTEQMA4GA1UEBRMHNTI4MDM5NDEfMB0GA1UE
# AxMWRGVsbCBUZWNobm9sb2dpZXMgSW5jLjCCAaIwDQYJKoZIhvcNAQEBBQADggGP
# ADCCAYoCggGBALmW9IlCjy/PBE5ZGADPVlIbsNS6S1FCnWSd1/hB10YM3Qc0n5CJ
# 2cHiOKgUiTm61a7Qzh7m67+IQzMMpBHHMBHQJsr71W4U2EiOnOHNAm403oM8MBNb
# cOhC6cknoO1DjeL1VNTIffhn9oGZvg0XXQca7vB3gqC1IoAcksg0CWh5M4D8V9X+
# X3aAjFB6MWOiiInFq2GQeH/Pc35PoSb4i/ArpzDCp1Uqlz6fDbKkRIlDII0HbXuH
# PJvNUxIg3Ki9i9/mng3FnLJ2X7Y0gPyuvkniJNi21d9mr9VOSk3HvXHZq1YdRLRb
# rj8WtgwprmlRrnAGbaFhPPkUG2xPDOU9COzcayb6ghfZnXK4UU88pcQDEXNLWTmD
# 63ygETmuGexzCQ8pp1kbt/cXKN/xAkxGFpyNpJPOjrm8uXNpyjpy3iwaTkaNcsEr
# z0bP51nEYdSKosODq2nbLnbmFXgj9we2pvix6zeHhYKl9TRlPbAsccqiTRBBhGkj
# MAb9aPvpy1fiIQIDAQABo4IBNTCCATEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU
# 96wO+HUdY4Gik830JkyxIJ5lRg4wHwYDVR0jBBgwFoAUzolPglGqFaKEYsoxI2HS
# Yfv4/ngwZwYIKwYBBQUHAQEEWzBZMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5l
# bnRydXN0Lm5ldDAyBggrBgEFBQcwAoYmaHR0cDovL2FpYS5lbnRydXN0Lm5ldC9l
# dmNzMi1jaGFpbi5wN2MwMQYDVR0fBCowKDAmoCSgIoYgaHR0cDovL2NybC5lbnRy
# dXN0Lm5ldC9ldmNzMi5jcmwwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMCAGA1UdIAQZMBcwBwYFZ4EMAQMwDAYKYIZIAYb6bAoBAjANBgkqhkiG
# 9w0BAQsFAAOCAgEAJaPgxf52Qx0bZY+xlNtpkPMudPhaEcommXI8S7HpTLWMuUM4
# 1VK5zP9Gn+8FvBJdh0ChuBKhcyjje3/3Mkv63XA/2L8XyfMzksMR3FTz0t5arrCa
# ojmwRANDojFAhd//v7MbCDDotvGDl7VUTdILo5Zsi7Vb53965JaJVMJu7/rbA6mK
# fGzw1LENLwHdN9vhQblicnwTZbp0OdhN0BX1KNg1Z+GWBQmSx19c69oMYvC//M8u
# DEFrdnEkNQoh3bFE0ybjoV0K0aH0GB1de9LbHOEuzyKiFNtIbl7ssxD8IP3IXVSk
# 7gfFhPaNxBqLcM5aOSf5/9UGnXRuCEx8Co+nS9RG+8r3uLEXq+5cSijZdi5z9hz6
# bwv/uLeOj0u09CAC6gB2BtT35Pli4jzrdce46iFijtaryiCSVBBDoJ2PQx8BixYM
# c0lvgBiBoSOhs9W93VS5nxTRze2l8XP7J6p8mscuhdScr3Vned1uyVY5dvWjk/YB
# Ie7pwxzc/vZ5/LDJtdrQ1rUDnX29XuKVgmgkXfiwaPiyEKFNHrMwog853rGzqcyk
# yngRfGTvUng9iBZHs6Uhg2m5eA2NkscyV1qVv/n7AcTlrf9gqAB4U7No3qNBdbCl
# YdCfzjwKYUXURawJf42LLiLtBDt0u9rTFspNQEpLZDHaxTgGp/uNgd/0DAYxghsm
# MIIbIgIBATB3MGMxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMu
# MTwwOgYDVQQDEzNFbnRydXN0IEV4dGVuZGVkIFZhbGlkYXRpb24gQ29kZSBTaWdu
# aW5nIENBIC0gRVZDUzICEHy3jaU2EO8YregKt11bePUwDQYJYIZIAWUDBAIBBQCg
# gZowGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLgYKKwYBBAGCNwIBDDEgMB6gHIAaAEQAZQBsAGwAIABTAG8A
# bAB1AHQAaQBvAG4wLwYJKoZIhvcNAQkEMSIEIDZO/DDd26UuWAFhZW2GPMEy1kzq
# otiYI5dnXM2NNUnuMA0GCSqGSIb3DQEBAQUABIIBgBORj4Rkqljc4P+w9Zt5I6ei
# AARgNyxv9Do5UufOfjvaL7apt0F4LXvd4i1KhR7jeNFuCxC/e6MnoQVxCk7fhtpK
# 0sEdh7JoAoGXIHz9QE/mvrpYrxOPByGKOT5pKhreNOS229eccvdoIuOrc/5c4ZgV
# BVWx6eJq4RfMSk71KiNnN3T1XB0Oa9t71oDAS4Zl9wEaUIFynm8pNkQQgvz6NwOx
# FlN1dN6bgamFit8EKUtbIdsc+mmBCDN3RHTI9GtXhpm3erMgLfCxllAaeEDPgueh
# hP4E4BQvTb2LyxQwZYtP7eVMN9pzPxAa+6P2PSuPfwwxO5DFs/OmCmY7gx5VL1qL
# bJ8V0QbJLRPsmfzzp6ASTib4HXNMz7nQA35IWEhYn0GT9oooIDWwQXHOHmIbdnlE
# Xi0wFib/O3ZGC9n/NxcZavGkUAd4JECJ4L0BThUha/UQbjitLOi2OxeKaeDSskBj
# 6gnHZGBQUJyWjs95lA7q6pXXi/9yWEd3MmZ4mCzL1aGCGGMwghhfBgorBgEEAYI3
# AwMBMYIYTzCCGEsGCSqGSIb3DQEHAqCCGDwwghg4AgEDMQ0wCwYJYIZIAWUDBAID
# MIHzBgsqhkiG9w0BCRABBKCB4wSB4DCB3QIBAQYKYIZIAYb6bAoDBTAxMA0GCWCG
# SAFlAwQCAQUABCABIBhgq34QAnuQ+enlH7y/jGlzCnZyQjsY1M5BjxpSjAIIM/UZ
# OEzHbBMYDzIwMjQxMDIyMDQxNDM4WjADAgEBoHmkdzB1MQswCQYDVQQGEwJDQTEQ
# MA4GA1UECBMHT250YXJpbzEPMA0GA1UEBxMGT3R0YXdhMRYwFAYDVQQKEw1FbnRy
# dXN0LCBJbmMuMSswKQYDVQQDEyJFbnRydXN0IFRpbWVzdGFtcCBBdXRob3JpdHkg
# LSBUU0EyoIITDjCCBd8wggTHoAMCAQICEE5A5DdU7eaMAAAAAFHTlH8wDQYJKoZI
# hvcNAQELBQAwgb4xCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMu
# MSgwJgYDVQQLEx9TZWUgd3d3LmVudHJ1c3QubmV0L2xlZ2FsLXRlcm1zMTkwNwYD
# VQQLEzAoYykgMjAwOSBFbnRydXN0LCBJbmMuIC0gZm9yIGF1dGhvcml6ZWQgdXNl
# IG9ubHkxMjAwBgNVBAMTKUVudHJ1c3QgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhv
# cml0eSAtIEcyMB4XDTIxMDUwNzE1NDM0NVoXDTMwMTEwNzE2MTM0NVowaTELMAkG
# A1UEBhMCVVMxFjAUBgNVBAoMDUVudHJ1c3QsIEluYy4xQjBABgNVBAMMOUVudHJ1
# c3QgQ29kZSBTaWduaW5nIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgLSBD
# U0JSMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKeBj/cURbZiQ/LY
# rtMlXkhPUb/FfZ9QHDXR1n5hKpQZbSdGpKYaXfdUUWqAIsaoZnVNVIPJXmgbq/Zb
# ZLCtrSC9VO9Ga20C50WudfaOirkyLou4dxxSTXmIX6U6GMlQLJcnLb/aAH1jf+8y
# 7EaHY9uan8NaITZ7+ZvVyqBuciz84fGecE0IVhVvkKv7SLq518GCeIVlLn+1ycDi
# FLc3EUEG4orgqPblfrZ4BQHDYO1PB0EuChNJ45Cbf929+qy/ZFHRXJu09VznXP87
# m6WgGtd9CbLCt/9uHLzIfebpK/xysxTpSlUShJxEJXUd9irwT6UgPWgl62GXfA/l
# tj3zrsPBEbwbjszgRzBeQgCGceNYrAbKZR97lKZLV2cMfl6teGdbVeNe68fY7Exu
# hsvz3Pifh6pyWBIPfab4+EI5Ozws5DJNSYzg4QDCOKCc+oQ+QdxuVq7GGlv0Z2gF
# Ac0bv66HvJ1T9i7otmvkmd7FT4dYqNJlHsgf1XJu7lkcVzsJcp3XyreQxs17RZKR
# QgNMfT/K8qq4wg6G8xCfRi6kZoZoWmgYcCk4EYBga4pDo3Ns47NrN//mnWcBkobf
# L0jR+1Bg1Vz+IdMBQmP+73C0F8CPqO7TwUtfEur9/S4Oh0Rg46n0whij4/3ODIQi
# DfOneNqT89s4z7kvM8b/BzxevkXTAgMBAAGjggErMIIBJzAOBgNVHQ8BAf8EBAMC
# AYYwEgYDVR0TAQH/BAgwBgEB/wIBATAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYB
# BQUHAwgwOwYDVR0gBDQwMjAwBgRVHSAAMCgwJgYIKwYBBQUHAgEWGmh0dHA6Ly93
# d3cuZW50cnVzdC5uZXQvcnBhMDMGCCsGAQUFBwEBBCcwJTAjBggrBgEFBQcwAYYX
# aHR0cDovL29jc3AuZW50cnVzdC5uZXQwMAYDVR0fBCkwJzAloCOgIYYfaHR0cDov
# L2NybC5lbnRydXN0Lm5ldC9nMmNhLmNybDAdBgNVHQ4EFgQUgrrWPZfOn89x6JI3
# r/2ztWk1V88wHwYDVR0jBBgwFoAUanImetAe733nO2lR1GyNn5ASZqswDQYJKoZI
# hvcNAQELBQADggEBAB9eQQS2g3AkUyxVcx1lOsDstHsEmF5ZOBMJpFmUQl5Qv09s
# biUgkJNYQA31GbRi7iRewgFYFQIdEAlvqNT7kn43OD4vFH2PHUM2ZLNmE18UzKVx
# 91shS8aXvtyV/HB9ERzTId3QJDkpxf4KGqXPe3nuOm/e3L/pEd0WgwjTLI1/TagU
# eS8FYVI462DzFGh9y7KKrcCUXOQmDiyK3UbDzuRWUcVW44W4TZtFcosH8Yr7Sbhf
# 0fKWgV1pUiTxCCPS1iMP64vXfovBk2v68WJ7WOlQm5duF4gN4cZDmNeBYbaFnUfs
# sZ6uPyA7Q53Yohzg1HwIwq92BvhiZnq29/rIrzUwggZvMIIEV6ADAgECAhAlvCvz
# KcoQfx6puoiF1J07MA0GCSqGSIb3DQEBDQUAMGkxCzAJBgNVBAYTAlVTMRYwFAYD
# VQQKDA1FbnRydXN0LCBJbmMuMUIwQAYDVQQDDDlFbnRydXN0IENvZGUgU2lnbmlu
# ZyBSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IC0gQ1NCUjEwHhcNMjEwNTA3
# MTkyMjE0WhcNNDAxMjI5MjM1OTAwWjBOMQswCQYDVQQGEwJVUzEWMBQGA1UEChMN
# RW50cnVzdCwgSW5jLjEnMCUGA1UEAxMeRW50cnVzdCBUaW1lIFN0YW1waW5nIENB
# IC0gVFMyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtQMqBraETzTM
# njG+6o7Ge24gJA8D172BNjPmb9I+u8SeqqDMZl1CYDRR4i1hg7o8nmi4S8NmjqXe
# K7qbLUGl3tDLVwUtiNnARohtPDUNGZCsuAwZ8EzF20Vb3DvCvI1EAOA4//9dyM8I
# mj3Usut7lcPEpQDgYgFkWV+M43uLqflFt8awogo3Q7hGgauGfn8v3vBf680gzKUt
# MeOoLpmb4Hjd9NtdgmN9MDmIfiQG5nxghHjIXCnllcv1e0/PWNyQz6eiexRUxOA3
# mDDBm7aunCn2ayVD5xJqPhmLvsDngddKMAh+fI3fPPNIkyHegYNqnQA+12C60bNi
# CJbptkkAOPRcdg3ad2o9oJXeHqHMWXpen8/pdl1A8rUVtWBoLPNaySOD2PUaa2ko
# pLbUrmIG3iZFvd7pVneq3GSwQc3ME/FdcXSylAhLTzJufnC4d+nVMjfCet5CEuhx
# HOLYYr+qa0GGBlvmab4mCfSXwv5M9IByhG7b3sUHqY4Vom3hG+AJD/WgB6C7xHdz
# CTwHk40BtRJnLU0ZtbjFyRCrcM9C/6UnHdYS1uQYRGD7OV2Eu2a1UxKdAxSCZSm0
# 7Ely/bND5cMCKSS6H/i4vl2jty6p/M9i2fqXxBN441W5WnqE6/+7z2mIwLb5i2CF
# QRBQxwUQ0l52nT417PZPivkSez+vCzcCAwEAAaOCASwwggEoMBIGA1UdEwEB/wQI
# MAYBAf8CAQAwHQYDVR0OBBYEFCYP8MRICBvN3ZH1VFS2s7P8mfEIMB8GA1UdIwQY
# MBaAFIK61j2Xzp/PceiSN6/9s7VpNVfPMDMGCCsGAQUFBwEBBCcwJTAjBggrBgEF
# BQcwAYYXaHR0cDovL29jc3AuZW50cnVzdC5uZXQwMQYDVR0fBCowKDAmoCSgIoYg
# aHR0cDovL2NybC5lbnRydXN0Lm5ldC9jc2JyMS5jcmwwDgYDVR0PAQH/BAQDAgGG
# MBMGA1UdJQQMMAoGCCsGAQUFBwMIMEUGA1UdIAQ+MDwwMAYEVR0gADAoMCYGCCsG
# AQUFBwIBFhpodHRwOi8vd3d3LmVudHJ1c3QubmV0L3JwYTAIBgZngQwBBAIwDQYJ
# KoZIhvcNAQENBQADggIBAHY9RmiFXwnAzsn4x7jXfqdcOwtGc84iU4s49hG6d8TC
# hyGPJ9kMlevoS+Vc15AVb6gqLIpq4CIRNHn6vZZ5yHYWzbFE6nFRD5tVyRh81YJ5
# nPOmt5OpBThyAgaXoaiyeX5eCOJubHmaqIeUzn+PVTZAD58/UdVmvnurhuZuh7pO
# Y12x2I4fy2fDDXDaeuuTshSE0j59kz8WDDagXHkAnwtu5YQq2IjBbQS3N/OSmnDg
# OwP9zbsngs4v/I3kssq++CWFxu10yD01XzgJPXlP6xvgQV6ldIE/URXA+EmIj7q7
# BdStRYIzecEljV9UPZHkuJ8XmABdrSjlT18b+/hUtaXEJPzwdjv4DV7MR7DKqrtu
# Ud9TtUka8WCHt/n9aQZ1X3PWEZDygFiO5cMPA5iMBFOzKYffP/ew6UxXgSREeWj+
# GzYH1mU97G/WwrWqYXxmBuzS5WmA+HGSLlziEUYYRUvW+gVk77veBspDJb3fjckB
# dGGI2/DHpj3jDHG8f0vnyOBu4NqA+QCewGsl1aO6XCv+xGAgFEoHIzHlGsuRRLKa
# e0PxW5i1IUu4MTsiVO55YfealBtmJyrG3+FlXe9xOeZQJf2HNLmuXXwnO+dlk/go
# hLFvhpMsk5O2cK+h7sikYamEO/sKt/i4bSbuR071XgX6nA8RfdfLka5DIPcVWWO8
# MIIGtDCCBJygAwIBAgIQW3AmzJb2eBq7hfYR9W27bjANBgkqhkiG9w0BAQ0FADBO
# MQswCQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjEnMCUGA1UEAxMe
# RW50cnVzdCBUaW1lIFN0YW1waW5nIENBIC0gVFMyMB4XDTI0MDExOTE2NDc0N1oX
# DTM1MDQxODAwMDAwMFowdTELMAkGA1UEBhMCQ0ExEDAOBgNVBAgTB09udGFyaW8x
# DzANBgNVBAcTBk90dGF3YTEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjErMCkGA1UE
# AxMiRW50cnVzdCBUaW1lc3RhbXAgQXV0aG9yaXR5IC0gVFNBMjCCAiIwDQYJKoZI
# hvcNAQEBBQADggIPADCCAgoCggIBAKqGBDhej2i/g/Va/VSbxX06dZ3Epy1PbenQ
# BR9R4zO7L186sZZUiukIfDStiYNVpJ8CzCML2Bt6QKTMn0LqE398uOC3SgIF4oNJ
# BG8Ghs1zQamD1Jhn+vRSGXrjSlkoh1YXXUjxhpELuCJk20H5XVS1NaRuONwIDRpW
# GEDDfpg8QjOEDcWlYVHOIG1PAMtC8Kh1G9tG/incG57X+BgFUXYwm3S9lR8ZU2UV
# RyxWY2vpukisCji2wXL9IAqjdBprB3/R3awXzrUcx3qJDOxtHDCNBfCvPZfMNbS1
# BQNmup52/DnayJrWEhLkQcKFIkDwy7qI6dKHwqvGNDvlqw0ABg4GtYt70Qsi2jyo
# yVZ78DUElupZRoyP1KC1qYOwzoT7S0TlQagW86/a0aAncN8H7zfzrpHO1CF/hpjc
# Xu6PwNpH22nKELmRlYAVY/ErGsKWoR/C9zzU9n0kByWoVJRvClXb2yRDbi47ontJ
# u7XWGI/ZBLO+6se1ZJpLzlJhHisFHmM3Rp2xydVeh6Tq1zSyIUIXuDooOl6l7T79
# Nxd/YyDye9ZfyvMUP+HO/4p3lGZticHg7H8EcDhkJ/WnF31NygyBG8Xl8TbFeq59
# KaRHNTj6DfRTAykF/G+hi8nN8biIQNPS254lMa3X5lrYBLSEuwRGYWb/XTLe/NM+
# fE4Y737fAgMBAAGjggFlMIIBYTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBT1dhr4
# EJiSoRt3qQAs8ZViAgt5JzAfBgNVHSMEGDAWgBQmD/DESAgbzd2R9VRUtrOz/Jnx
# CDBoBggrBgEFBQcBAQRcMFowIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLmVudHJ1
# c3QubmV0MDMGCCsGAQUFBzAChidodHRwOi8vYWlhLmVudHJ1c3QubmV0L3RzMi1j
# aGFpbjI1Ni5wN2MwMQYDVR0fBCowKDAmoCSgIoYgaHR0cDovL2NybC5lbnRydXN0
# Lm5ldC90czJjYS5jcmwwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEwGA1UdIARFMEMwNwYKYIZIAYb6bAoBBzApMCcGCCsGAQUFBwIBFhto
# dHRwczovL3d3dy5lbnRydXN0Lm5ldC9ycGEwCAYGZ4EMAQQCMA0GCSqGSIb3DQEB
# DQUAA4ICAQCpq32/GgCFW9ztcSZelIKvXIJL+hw5xVO1wwbdA2B++WGaQSDCrkEX
# LqVCCJEJXpcwmIFF1rK1hD2L6YcH2gE/4AhYZxEglB7AFo5jd72bbAWNPbXLmjGp
# SlxiMqITzpCcDceQT2fD4Kh/h4RL1/LBIQ8Q5xe5+70JzL6KpgH+TYJPaSCadWvk
# DfdQJlP8M/f+G66nasCo6x6vItM9YBWfuuTVKaS1V5+xZfaxTGHV0sjat6yqGB8g
# GIqm+PUH+XIr9mPYJZwW/vuU34Z0oiC08gjfFu85gHY6krHQloNq2nxTiVkbDVzx
# uynyIU9hLCSJ+HYJf9lokI5XDGTVdgBxWfPUhMg8oYh/qG/zvW5/sKiO5pNs6RTF
# dRwMK87yB/u1rtRBMb/BzGmYGK5bCI+rXGS5hGq9XDih309Ct0tbUtPe9zvLn2/C
# WUIiTgsYtyLIL/xqCYXtUClResSUS7ZxZYpKhppLeEtWiqHeL4uTWzLMobnvqbYM
# 2AYLFzC/DW+Pk6zLEfXxxwCe0BnXnF+OVHxrqUM7Y9zBRKu9jDpD8HI/JJXNhJFd
# IQANeGsNXCMkn0yvNMsUWt6x5EVQ/a9vpwWCp3PPz+mS6nMqseHdogPmILwdZxpW
# wi72rF/KToGw5lodc8/SFPNQeCgFThVuhST4M6iIr3Rt9FLOjKiEnjGCBBowggQW
# AgEBMGIwTjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xJzAl
# BgNVBAMTHkVudHJ1c3QgVGltZSBTdGFtcGluZyBDQSAtIFRTMgIQW3AmzJb2eBq7
# hfYR9W27bjALBglghkgBZQMEAgOgggGLMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjQxMDIyMDQxNDM4WjArBgkqhkiG9w0BCTQx
# HjAcMAsGCWCGSAFlAwQCA6ENBgkqhkiG9w0BAQ0FADBPBgkqhkiG9w0BCQQxQgRA
# /PBouPMe/z2GBvKYPzpyow4UqyG8AX130ZSkVK/ihEHSiVw1lDCbYieb0El/06fr
# LKA7nL4Fy1D7Tso8wQxGwTCB0AYLKoZIhvcNAQkQAi8xgcAwgb0wgbowgbcwCwYJ
# YIZIAWUDBAIDBEA5EUIuFwI+qpkkmXQODsjo0nLTVfxc9mz5EVavl1U05ICv07x8
# TFtX79H/vNt1FGXg1AVahU6bETnZ9+xV1f4kMGYwUqRQME4xCzAJBgNVBAYTAlVT
# MRYwFAYDVQQKEw1FbnRydXN0LCBJbmMuMScwJQYDVQQDEx5FbnRydXN0IFRpbWUg
# U3RhbXBpbmcgQ0EgLSBUUzICEFtwJsyW9ngau4X2EfVtu24wDQYJKoZIhvcNAQEN
# BQAEggIAnLfklGDh9K5NKpnjP6Cp11iNuNFrGrn4y/mjzvRjWpmNNe7Kkk92JlsJ
# YtKsXwKKqlKbbr+WXXivSeMJLJRdBy8nzE9tCk8edhJtdQEzgbs8N08qrDHEr1EP
# JNiExyLKllMY/ad2useN1CXxf7Oz3X56vaqon3PkR/s31XucNCZg79PLNt9zMQ3E
# BCn76/zhRRXZDSaRFGeMXRijVA83ocwGMes+Fd5nkMVrKxzV3oQoNNvC9t9QKtTf
# Y9oXey85zQzcChOBlsGhe4N5ONtD9JF8rFxzBb8dvHbjESmZCSV/+FVzBl8Dle3X
# fHejVpvNB5kL7FhTCxyj3agfBXO4fYzxVqlUSWI9qMGJJv6XV/fw6gLsqQBPR7aC
# GKnUVN6Qi3WPZ7OxZ1mBsYNPqKh2EE+Lx4A4KDK3hiVvxLPdcUXCZpE2TAS10ZDh
# GTkkXHhtOpuKf0LYSlR8OC/BbdlRpMxWu97Yo3m1unMq+8nlws6Svs5Vt5rM7TyI
# vQm8m+8B5c2dYII4pIlGZ1t3Aa1t4q2FD6lRfZdvfSOFZGoX1dnPo5AOK9Y7Rw9d
# bzMtc9yOAEjmwaOmur2DF0ofyWtTipp9sA3h7qXUVqyjKwCXdrJ2wHMoRUIzkm8T
# yDayS0Or3565DYwZM/+2NOfPVamLIJVOcVYi/XE/jm86d390cvc=
# SIG # End signature block
