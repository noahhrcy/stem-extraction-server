# Variables utilisateur
$installDir = "$env:USERPROFILE\Documents\demucs-server"
$venvDir = "$installDir\venv"
$serverScript = "server.py"
$venvActivate = "$venvDir\Scripts\Activate.ps1"
$runPath = "$installDir\run-server.ps1"

Write-Host "Création du dossier d'installation dans $installDir"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Set-Location $installDir

# Vérifier Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python non trouvé. Installation via winget..."
    winget install -e --id Python.Python.3

    # Met à jour le PATH pour cette session
    $pythonPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    if (-not ($env:PATH -like "*$pythonPath*")) {
        $env:PATH += ";$pythonPath"
    }

    # Vérifie à nouveau
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Error "Python toujours non détecté. Redémarre PowerShell ou installe Python manuellement."
        exit 1
    }
}

# Créer l’environnement virtuel
Write-Host "Création de l'environnement virtuel..."
python -m ensurepip --upgrade
python -m venv $venvDir

if (-not (Test-Path $venvActivate)) {
    Write-Error "L'environnement virtuel n'a pas été créé correctement."
    exit 1
}

# Activer l’environnement virtuel
& $venvActivate

# Installer les dépendances Python
Write-Host "Installation des packages Python nécessaires..."
python -m pip install --upgrade pip
python -m pip install flask yt-dlp torchaudio==2.7.1 numpy openunmix demucs dora

# Préchargement du modèle
Write-Host "Préchargement du modèle htdemucs..."
python -m demucs --list

# Télécharger server.py personnalisé
Write-Host "Téléchargement du fichier server.py personnalisé..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/noahhrcy/stem-extraction-server/main/server.py" -OutFile "$installDir\$serverScript"

# Créer script de lancement
@"
`$env:Path = "$($venvDir)\Scripts;$env:Path"
python "$installDir\$serverScript"
"@ | Out-File -Encoding UTF8 -FilePath $runPath

Write-Host "`nInstallation terminée !"
Write-Host "Pour lancer le serveur :"
Write-Host "   Ouvrir PowerShell et exécuter :"
Write-Host "   powershell -ExecutionPolicy Bypass -File `"$runPath`""
Write-Host "`nServeur accessible sur : http://localhost:5000"
