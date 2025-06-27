# ============================
# Veraltete AD-Computer löschen (nach Bestätigung)
# ============================
# Nur ausführen auf Domänencontrollern oder Systemen mit AD-Modul

# Prüfen & ggf. installieren des AD-Moduls (nur auf Servern)
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory-Modul nicht gefunden. Versuche zu installieren..." -ForegroundColor Yellow
    try {
        Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop
        Write-Host "Modul erfolgreich installiert." -ForegroundColor Green
    } catch {
        Write-Host ("Fehler bei der Installation des AD-Moduls: {0}" -f $_) -ForegroundColor Red
        exit 1
    }
}

# Modul importieren
Import-Module ActiveDirectory

# Schwelle in Tagen (180 Tage)
$grenze = (Get-Date).AddDays(-180)

# Abfrage der veralteten Rechner
$veralteteComputer = Get-ADComputer -Filter * -Properties Name, LastLogonDate |
    Where-Object {
        $_.Enabled -eq $true -and $_.LastLogonDate -lt $grenze
    } |
    Sort-Object LastLogonDate

# Prüfung ob überhaupt veraltete Computer vorhanden sind
if ($veralteteComputer.Count -eq 0) {
    Write-Host "Keine veralteten Rechner gefunden." -ForegroundColor Green
    return
}

# Rechnerweise abarbeiten
foreach ($computer in $veralteteComputer) {
    $name = $computer.Name
    $lastLogon = $computer.LastLogonDate

    Write-Host "`n==============================="
    Write-Host "Computername: $name"
    Write-Host "Letzte Anmeldung: $lastLogon"
    $eingabe = Read-Host "Möchtest du diesen Rechner löschen? (j/n)"

    if ($eingabe -eq "j") {
        try {
            Remove-ADComputer -Identity $name -Confirm:$false
            Write-Host ">>> Rechner $name wurde gelöscht." -ForegroundColor Yellow
        } catch {
            Write-Host ("!!! Fehler beim Löschen von {0}: {1}" -f $name, $_) -ForegroundColor Red
        }
    } else {
        Write-Host ">>> Rechner $name wurde übersprungen." -ForegroundColor Cyan
    }
}
