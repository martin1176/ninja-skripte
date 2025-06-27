# Sicherstellen, dass das AD-Modul vorhanden ist
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory-Modul nicht gefunden. Versuche zu installieren..." -ForegroundColor Yellow
    try {
        Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop
        Write-Host "Modul erfolgreich installiert." -ForegroundColor Green
    } catch {
        Write-Host "Fehler bei der Installation des AD-Moduls: $_" -ForegroundColor Red
        exit 1
    }
}

Import-Module ActiveDirectory

# Schwelle: 180 Tage
$grenze = (Get-Date).AddDays(-180)

# Veraltete Rechner sammeln
$veralteteComputer = Get-ADComputer -Filter * -Properties Name, LastLogonDate |
    Where-Object {
        $_.Enabled -eq $true -and $_.LastLogonDate -lt $grenze
    } |
    Sort-Object LastLogonDate

# Keine Treffer
if ($veralteteComputer.Count -eq 0) {
    Write-Host "Keine veralteten Rechner gefunden." -ForegroundColor Green
    return
}

# Rechner einzeln abfragen
foreach ($computer in $veralteteComputer) {
    $name = $computer.Name
    $lastLogon = $computer.LastLogonDate

    Write-Host "`nComputer: $name"
    Write-Host "Letzte Anmeldung: $lastLogon"
    $eingabe = Read-Host "Möchtest du diesen Rechner löschen? (j/n)"

    if ($eingabe -eq "j") {
        try {
            Remove-ADComputer -Identity $name -Confirm:$false
            Write-Host ">>> Rechner $name wurde gelöscht." -ForegroundColor Yellow
        } catch {
            Write-Host "!!! Fehler beim Löschen von $name: $_" -ForegroundColor Red
        }
    } else {
        Write-Host ">>> Rechner $name wurde übersprungen." -ForegroundColor Cyan
    }
}
