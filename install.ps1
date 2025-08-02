# Variables utilisateur
$installDir = "$env:USERPROFILE\Documents\demucs-server"
$venvDir = "$installDir\venv"
$demucsRepo = "https://github.com/facebookresearch/demucs.git"
$serverScript = "server.py"
$venvActivate = "$venvDir\Scripts\Activate.ps1"

Write-Host "📁 Création du dossier d'installation dans $installDir"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Set-Location $installDir

# Vérifier Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "🐍 Python non trouvé. Installation via winget..."
    winget install -e --id Python.Python.3
    $env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"
}

# Vérifier git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "🔄 Git non trouvé. Installation..."
    winget install -e --id Git.Git
}

# Vérifier yt-dlp
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "📥 Téléchargement de yt-dlp.exe..."
    Invoke-WebRequest https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -OutFile "$installDir\yt-dlp.exe"
    $env:Path += ";$installDir"
}

# Vérifier ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "🎞 Installation de ffmpeg via winget..."
    winget install -e --id Gyan.FFmpeg
}

# Créer un environnement virtuel
Write-Host "📦 Création de l'environnement virtuel..."
python -m venv $venvDir
& $venvActivate

# Installer les packages Python
Write-Host "📦 Installation des packages Python nécessaires..."
pip install --upgrade pip
pip install flask yt-dlp torchaudio

# Cloner Demucs
Write-Host "📥 Clonage de Demucs..."
git clone $demucsRepo
Set-Location "$installDir\demucs"
pip install -e .

# Télécharger le modèle htdemucs
Write-Host "⬇️ Préchargement du modèle htdemucs..."
python -c "from demucs.pretrained import get_model; get_model('htdemucs')"

# Retour dans le dossier principal
Set-Location $installDir

# Créer un script de lancement
$runScript = @"
`$env:TORCHAUDIO_AUDIO_BACKEND = "soundfile"
Set-Location "$installDir"
& "$venvDir\Scripts\Activate.ps1"
python $serverScript
"@
$runPath = "$installDir\run.ps1"
$runScript | Set-Content $runPath -Encoding UTF8

Write-Host ""
Write-Host "✅ Installation terminée !"
Write-Host "➡️ Pour lancer le serveur :"
Write-Host "   Ouvrir PowerShell et exécuter :"
Write-Host "   `powershell -ExecutionPolicy Bypass -File $runPath`"
Write-Host ""
Write-Host "🌐 Serveur accessible sur : http://localhost:5000"
