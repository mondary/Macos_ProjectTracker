#!/bin/bash
# Installation du cron job pour Project Tracker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="$SCRIPT_DIR/.venv"
TRACKER_PATH="$SCRIPT_DIR/tracker.py"
LOG_PATH="$SCRIPT_DIR/tracker.log"
PYTHON_PATH="$VENV_PATH/bin/python3"

echo "🔧 Project Tracker - Installation"
echo "=================================="

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 non trouvé. Installez Python3 d'abord."
    exit 1
fi

# Créer le venv si nécessaire
if [ ! -d "$VENV_PATH" ]; then
    echo "📦 Création de l'environnement virtuel..."
    python3 -m venv "$VENV_PATH"
fi

# Installer les dépendances dans le venv
echo "📦 Installation des dépendances..."
"$VENV_PATH/bin/pip" install --upgrade pip --quiet
"$VENV_PATH/bin/pip" install google-genai --quiet

# Vérifier config.json
if [ ! -f "$SCRIPT_DIR/config.json" ]; then
    echo "❌ config.json non trouvé!"
    echo "   Copiez config.example.json vers config.json et ajoutez votre clé API."
    exit 1
fi

# Vérifier que la clé API est configurée
if grep -q "YOUR_GEMINI_API_KEY_HERE" "$SCRIPT_DIR/config.json"; then
    echo "⚠️  N'oubliez pas de configurer votre clé API Gemini dans config.json"
fi

# Rendre le script exécutable
chmod +x "$TRACKER_PATH"

# Créer le cron job (utilise le Python du venv)
CRON_CMD="0 * * * * cd $SCRIPT_DIR && $PYTHON_PATH $TRACKER_PATH >> $LOG_PATH 2>&1"

echo ""
echo "📋 Cron job à ajouter:"
echo "   $CRON_CMD"
echo ""

# Vérifier si le cron existe déjà
if crontab -l 2>/dev/null | grep -q "tracker.py"; then
    echo "⚠️  Un cron job Project Tracker existe déjà."
    read -p "Voulez-vous le remplacer? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation annulée."
        exit 0
    fi
    # Supprimer l'ancien
    crontab -l | grep -v "tracker.py" | crontab -
fi

# Ajouter le nouveau cron
(crontab -l 2>/dev/null || echo "") | { cat; echo "$CRON_CMD"; } | crontab -

echo "✅ Cron job installé! Le tracker s'exécutera toutes les heures."
echo ""
echo "📁 Fichiers:"
echo "   - Config:   $SCRIPT_DIR/config.json"
echo "   - Projets:  $SCRIPT_DIR/projects.json (généré au premier scan)"
echo "   - Logs:     $LOG_PATH"
echo "   - Venv:     $VENV_PATH"
echo ""
echo "🚀 Pour lancer manuellement: $PYTHON_PATH $TRACKER_PATH"
echo "📋 Pour voir les crons:      crontab -l"
echo "🗑️  Pour supprimer le cron:  crontab -l | grep -v tracker.py | crontab -"
