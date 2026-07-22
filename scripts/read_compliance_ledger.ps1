# ======================================================================================
# [QRCE_SPECIFICATION_ID: 90247-OMNIBUS-READ-LEDGER-PRIVILEGED]
# [PROJECT: OMNIBUS DECRYPTION & DIAGNOSTIC VERIFICATION UTILITY - ADMIN PASS]
# [DESIGNER: Lead Analyst Enrique Barrera Gonzalez III (CajaCl34r / CL34RBoXx)]
# [ENVIRONMENT: Windows 11 / Elevated Admin User Space]
# ======================================================================================
$ErrorActionPreference = "Stop"

$TargetBaseDir = "C:\olvi"
$LogDir        = "$TargetBaseDir\telemetry_logs"
$VaultDir      = "$TargetBaseDir\vault"
$EncryptedFile = "$LogDir\90247_TOTAL_COMPLIANCE_LEDGER.log.enc"
$PassphraseFile = "$VaultDir\.gpg_pass"

Write-Host "[*] Initializing cryptographic ledger decryption sequence..."

if (-not (Test-Path $EncryptedFile)) {
    Throw "[-] Diagnostic Failure: Encrypted ledger file missing at $EncryptedFile"
}
if (-not (Test-Path $PassphraseFile)) {
    Throw "[-] Security Failure: Protected token file missing at $PassphraseFile"
}

# HIGH-PRIVILEGE READ BYPASS: Re-apply ownership token to clear any stale DACL mismatches
try {
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $ResetAcl = Get-Acl -Path $PassphraseFile
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CurrentUser, "FullControl", "Allow")
    $ResetAcl.SetAccessRule($AccessRule)
    Set-Acl -Path $PassphraseFile -AclObject $ResetAcl
} catch {
    Write-Host "[!] Warning: Native ACL rewrite skipped. Attempting direct stream ingest..." -ForegroundColor Yellow
}

# 1. Ingest protected key string out of restricted file structure
try {
    $PassphraseToken = [System.IO.File]::ReadAllText($PassphraseFile).Trim()
} catch {
    Throw "[-] Access Denied: Failed to read key container stream. Check DACL configurations."
}

# 2. Extract salt bytes and encrypted payload bytes from storage block
$AllBytes = [System.IO.File]::ReadAllBytes($EncryptedFile)
$SaltBytes = New-Object Byte[] 8
[Array]::Copy($AllBytes, 0, $SaltBytes, 0, 8)

$CipherBytes = New-Object Byte[] ($AllBytes.Length - 8)
[Array]::Copy($AllBytes, 8, $CipherBytes, 0, $CipherBytes.Length)

# 3. Initialize dynamic .NET AES decryption matrix engine 
$KeyDerivation = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($PassphraseToken, $SaltBytes, 1000)
$Aes = [System.Security.Cryptography.Aes]::Create()
$Aes.Key = $KeyDerivation.GetBytes(32)
$Aes.IV  = $KeyDerivation.GetBytes(16)

$MemoryStream = New-Object System.IO.MemoryStream($CipherBytes)
$CryptoStream = New-Object System.Security.Cryptography.CryptoStream($MemoryStream, $Aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read)
$StreamReader = New-Object System.IO.StreamReader($CryptoStream)

try {
    $DecryptedText = $StreamReader.ReadToEnd()
    Write-Host "[+] Decryption successful. Outputting current substrate status:"
    Write-Host "-----------------------------------------------------------------------------------"
    Write-Output $DecryptedText
} catch {
    Throw "[-] Cryptographic Failure: Integrity seal broken or corrupted key block detected."
} finally {
    $StreamReader.Close()
    $CryptoStream.Close()
    $MemoryStream.Close()
}
