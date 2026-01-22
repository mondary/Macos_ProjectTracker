#!/usr/bin/env python3
"""
Project Tracker - Analyse et surveille tes projets de développement
"""

import json
import os
import subprocess
import hashlib
import time
import html
from datetime import datetime
from pathlib import Path
from google import genai

# ============================================================================
# CONFIGURATION
# ============================================================================

CONFIG_FILE = Path(__file__).parent / "config.json"
PROJECTS_FILE = Path(__file__).parent / "projects.json"
HTML_REPORT_FILE = Path(__file__).parent / "report.html"

def load_config():
    """Charge la configuration depuis config.json"""
    if not CONFIG_FILE.exists():
        raise FileNotFoundError(f"Config file not found: {CONFIG_FILE}")
    with open(CONFIG_FILE) as f:
        return json.load(f)

def load_projects():
    """Charge l'état des projets depuis projects.json"""
    if not PROJECTS_FILE.exists():
        return {}
    with open(PROJECTS_FILE) as f:
        return json.load(f)

def save_projects(projects):
    """Sauvegarde l'état des projets"""
    with open(PROJECTS_FILE, "w") as f:
        json.dump(projects, f, indent=2, ensure_ascii=False, default=str)

def write_html_report(projects, changes, output_path=HTML_REPORT_FILE):
    """Génère un rapport HTML simple"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    rows = []
    for name in sorted(projects.keys()):
        p = projects[name]
        types = ", ".join(p.get("types") or [])
        version = p.get("version") or ""
        last_scan = p.get("last_scan") or ""
        git = p.get("git") or {}
        branch = git.get("branch") or ""
        modified = git.get("modified_files")
        unpushed = git.get("unpushed_commits")
        modified = "" if modified is None else str(modified)
        unpushed = "" if unpushed is None else str(unpushed)
        analysis = p.get("analysis") or {}
        category = analysis.get("category") or ""
        tech = ", ".join(analysis.get("technologies") or [])
        description = analysis.get("description") or ""
        rows.append(
            "<tr>"
            f"<td>{html.escape(name)}</td>"
            f"<td>{html.escape(p.get('path', ''))}</td>"
            f"<td>{html.escape(types)}</td>"
            f"<td>{html.escape(version)}</td>"
            f"<td>{html.escape(branch)}</td>"
            f"<td>{html.escape(modified)}</td>"
            f"<td>{html.escape(unpushed)}</td>"
            f"<td>{html.escape(category)}</td>"
            f"<td>{html.escape(tech)}</td>"
            f"<td>{html.escape(description[:200])}</td>"
            f"<td>{html.escape(last_scan)}</td>"
            "</tr>"
        )

    changes_html = "".join(
        f"<li>{html.escape(c)}</li>" for c in (changes or [])
    ) or "<li>Aucun changement</li>"

    html_doc = f"""<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Project Tracker Report</title>
    <style>
      :root {{
        --bg: #0f1115;
        --fg: #e8e8e8;
        --muted: #a6adbb;
        --accent: #7bdff2;
        --table: #171a21;
        --border: #2a2f3a;
      }}
      body {{
        margin: 24px;
        font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
        background: var(--bg);
        color: var(--fg);
      }}
      h1 {{
        font-size: 20px;
        margin: 0 0 6px;
      }}
      .meta {{
        color: var(--muted);
        margin-bottom: 18px;
      }}
      .changes {{
        margin: 0 0 22px;
        padding: 12px 16px;
        background: var(--table);
        border: 1px solid var(--border);
        border-radius: 8px;
      }}
      table {{
        width: 100%;
        border-collapse: collapse;
        background: var(--table);
        border: 1px solid var(--border);
        border-radius: 8px;
        overflow: hidden;
      }}
      th, td {{
        padding: 10px 12px;
        border-bottom: 1px solid var(--border);
        text-align: left;
        vertical-align: top;
        font-size: 12px;
      }}
      th {{
        background: #11141a;
        color: var(--accent);
        position: sticky;
        top: 0;
      }}
      tr:hover td {{
        background: #141823;
      }}
      .small {{
        color: var(--muted);
        font-size: 11px;
      }}
    </style>
  </head>
  <body>
    <h1>Project Tracker Report</h1>
    <div class="meta">Généré le {html.escape(now)} • {len(projects)} projet(s)</div>
    <div class="changes">
      <strong>Changements</strong>
      <ul>{changes_html}</ul>
    </div>
    <table>
      <thead>
        <tr>
          <th>Projet</th>
          <th>Chemin</th>
          <th>Types</th>
          <th>Version</th>
          <th>Branche</th>
          <th>Modifiés</th>
          <th>Non poussés</th>
          <th>Catégorie</th>
          <th>Techs</th>
          <th>Description</th>
          <th>Dernier scan</th>
        </tr>
      </thead>
      <tbody>
        {''.join(rows)}
      </tbody>
    </table>
    <p class="small">Fichier source: {html.escape(str(PROJECTS_FILE))}</p>
  </body>
</html>
"""

    with open(output_path, "w") as f:
        f.write(html_doc)

def open_html_report(path=HTML_REPORT_FILE):
    """Ouvre le rapport HTML dans le navigateur par défaut (macOS)."""
    try:
        subprocess.run(["open", str(path)], check=False)
    except Exception:
        pass

# ============================================================================
# NOTIFICATIONS MACOS
# ============================================================================

def notify(title, message, sound=True):
    """Envoie une notification macOS"""
    sound_cmd = 'sound name "default"' if sound else ""
    script = f'display notification "{message}" with title "{title}" {sound_cmd}'
    subprocess.run(["osascript", "-e", script], capture_output=True)

# ============================================================================
# GIT UTILS
# ============================================================================

def run_git(project_path, *args):
    """Exécute une commande git dans un projet"""
    try:
        result = subprocess.run(
            ["git", "-C", str(project_path)] + list(args),
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.stdout.strip(), result.returncode == 0
    except Exception:
        return "", False

def is_git_repo(project_path):
    """Vérifie si le dossier est un repo git"""
    return (Path(project_path) / ".git").exists()

def get_git_status(project_path):
    """Récupère le statut git complet d'un projet"""
    if not is_git_repo(project_path):
        return None

    status = {}

    # Branche actuelle
    branch, ok = run_git(project_path, "rev-parse", "--abbrev-ref", "HEAD")
    status["branch"] = branch if ok else "unknown"

    # Dernier commit
    last_commit, ok = run_git(project_path, "log", "-1", "--format=%H|%s|%ci")
    if ok and last_commit:
        parts = last_commit.split("|")
        status["last_commit"] = {
            "hash": parts[0][:8],
            "message": parts[1] if len(parts) > 1 else "",
            "date": parts[2] if len(parts) > 2 else ""
        }

    # Fichiers modifiés (non commités)
    modified, ok = run_git(project_path, "status", "--porcelain")
    if ok:
        lines = [l for l in modified.split("\n") if l.strip()]
        status["modified_files"] = len(lines)
        status["modified_list"] = lines[:10]  # Max 10 fichiers

    # Commits non poussés
    unpushed, ok = run_git(project_path, "log", "@{u}..", "--oneline")
    if ok:
        lines = [l for l in unpushed.split("\n") if l.strip()]
        status["unpushed_commits"] = len(lines)
    else:
        # Pas de remote configuré
        status["unpushed_commits"] = -1

    # Stash
    stash, ok = run_git(project_path, "stash", "list")
    if ok:
        lines = [l for l in stash.split("\n") if l.strip()]
        status["stash_count"] = len(lines)

    # Remote URL
    remote, ok = run_git(project_path, "remote", "get-url", "origin")
    status["remote"] = remote if ok else None

    return status

# ============================================================================
# DETECTION DU TYPE DE PROJET
# ============================================================================

PROJECT_SIGNATURES = {
    "node": ["package.json"],
    "python": ["requirements.txt", "setup.py", "pyproject.toml", "Pipfile"],
    "rust": ["Cargo.toml"],
    "go": ["go.mod"],
    "swift": ["Package.swift", "*.xcodeproj", "*.xcworkspace"],
    "ruby": ["Gemfile"],
    "java": ["pom.xml", "build.gradle"],
    "php": ["composer.json"],
    "dotnet": ["*.csproj", "*.sln"],
}

def detect_project_type(project_path):
    """Détecte le type de projet basé sur les fichiers présents"""
    path = Path(project_path)
    types = []

    for ptype, signatures in PROJECT_SIGNATURES.items():
        for sig in signatures:
            if "*" in sig:
                if list(path.glob(sig)):
                    types.append(ptype)
                    break
            elif (path / sig).exists():
                types.append(ptype)
                break

    return types if types else ["unknown"]

def has_project_signatures(project_path):
    """Détecte rapidement si un dossier ressemble à un projet."""
    path = Path(project_path)
    if (path / ".git").exists():
        return True
    for signatures in PROJECT_SIGNATURES.values():
        for sig in signatures:
            if "*" in sig:
                if list(path.glob(sig)):
                    return True
            elif (path / sig).exists():
                return True
    return False

def iter_projects(projects_dir, max_depth=4):
    """Parcourt récursivement les dossiers à la recherche de projets."""
    skip_dirs = {
        ".git", "node_modules", ".venv", "dist", "build", ".tox",
        ".mypy_cache", ".pytest_cache", "__pycache__", ".idea", ".vscode"
    }
    for root, dirs, _files in os.walk(projects_dir):
        rel = Path(root).relative_to(projects_dir)
        depth = 0 if str(rel) == "." else len(rel.parts)
        if depth > max_depth:
            dirs[:] = []
            continue
        # Filtre des dossiers à ignorer
        dirs[:] = [d for d in dirs if not d.startswith(".") and d not in skip_dirs]
        if root == str(projects_dir):
            continue
        if has_project_signatures(root):
            yield root

def get_version(project_path):
    """Extrait la version du projet si possible"""
    path = Path(project_path)

    # package.json (Node)
    pkg = path / "package.json"
    if pkg.exists():
        try:
            with open(pkg) as f:
                data = json.load(f)
                return data.get("version")
        except:
            pass

    # Cargo.toml (Rust)
    cargo = path / "Cargo.toml"
    if cargo.exists():
        try:
            with open(cargo) as f:
                for line in f:
                    if line.startswith("version"):
                        return line.split("=")[1].strip().strip('"')
        except:
            pass

    # pyproject.toml (Python)
    pyproject = path / "pyproject.toml"
    if pyproject.exists():
        try:
            with open(pyproject) as f:
                for line in f:
                    if "version" in line and "=" in line:
                        return line.split("=")[1].strip().strip('"')
        except:
            pass

    return None

# ============================================================================
# ANALYSE AVEC GEMINI
# ============================================================================

def get_project_context(project_path):
    """Récupère le contexte d'un projet pour l'analyse IA"""
    path = Path(project_path)
    context = []

    # README
    for readme in ["README.md", "README.txt", "README", "readme.md"]:
        readme_path = path / readme
        if readme_path.exists():
            try:
                content = readme_path.read_text()[:3000]
                context.append(f"=== README ===\n{content}")
            except:
                pass
            break

    # Structure des fichiers (premier niveau + src/)
    files = []
    for item in path.iterdir():
        if item.name.startswith("."):
            continue
        if item.is_file():
            files.append(item.name)
        elif item.is_dir():
            files.append(f"{item.name}/")
    context.append(f"=== STRUCTURE ===\n{chr(10).join(files[:30])}")

    # Fichiers clés (début)
    key_files = [
        "main.py", "app.py", "index.js", "index.ts", "main.rs", "main.go",
        "App.tsx", "App.vue", "app.rb", "Main.java", "Program.cs",
        "package.json", "Cargo.toml", "pyproject.toml"
    ]

    for kf in key_files:
        kf_path = path / kf
        if kf_path.exists():
            try:
                content = kf_path.read_text()[:1500]
                context.append(f"=== {kf} ===\n{content}")
            except:
                pass

    # Aussi chercher dans src/
    src = path / "src"
    if src.exists():
        for kf in key_files:
            kf_path = src / kf
            if kf_path.exists():
                try:
                    content = kf_path.read_text()[:1500]
                    context.append(f"=== src/{kf} ===\n{content}")
                except:
                    pass

    return "\n\n".join(context)[:8000]  # Max 8000 chars pour Gemini

def analyze_with_gemini(project_name, context, config):
    """Utilise Gemini pour décrire le projet"""
    try:
        client = genai.Client(api_key=config["gemini_api_key"])

        prompt = f"""Analyse ce projet de développement et fournis une description concise.

Nom du projet: {project_name}

{context}

Réponds en JSON avec ce format exact:
{{
    "description": "Description fonctionnelle en 1-2 phrases (à quoi sert ce projet/app)",
    "technologies": ["liste", "des", "technos", "principales"],
    "category": "Une catégorie parmi: web-app, mobile-app, cli-tool, library, api, automation, game, other"
}}

Réponds UNIQUEMENT avec le JSON, rien d'autre."""

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt
        )
        text = response.text.strip()

        # Nettoyer le JSON si nécessaire
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        text = text.strip()

        return json.loads(text)
    except Exception as e:
        return {
            "description": f"Erreur d'analyse: {str(e)[:50]}",
            "technologies": [],
            "category": "unknown"
        }

def compute_project_hash(project_path):
    """Calcule un hash basé sur les fichiers clés du projet"""
    path = Path(project_path)
    hasher = hashlib.md5()

    # Hash des fichiers importants
    important_files = [
        "README.md", "package.json", "Cargo.toml", "pyproject.toml",
        "main.py", "index.js", "main.rs", "app.py"
    ]

    for f in important_files:
        fp = path / f
        if fp.exists():
            try:
                hasher.update(fp.read_bytes()[:2000])
            except:
                pass

    return hasher.hexdigest()[:12]

# ============================================================================
# MAIN TRACKER
# ============================================================================

def scan_projects(config):
    """Scanne et analyse tous les projets"""
    projects_dir = Path(config["projects_directory"]).expanduser()
    max_depth = int(config.get("scan_depth", 4))

    if not projects_dir.exists():
        raise FileNotFoundError(f"Projects directory not found: {projects_dir}")

    existing = load_projects()
    updated = {}
    changes = []

    for project_path in iter_projects(projects_dir, max_depth=max_depth):
        project_path = str(project_path)
        project_name = str(Path(project_path).relative_to(projects_dir))

        print(f"📁 Scanning: {project_name}")

        # Infos de base
        project_types = detect_project_type(project_path)
        version = get_version(project_path)
        git_status = get_git_status(project_path)
        current_hash = compute_project_hash(project_path)

        # Vérifier si on doit ré-analyser avec Gemini
        prev = existing.get(project_name, {})
        prev_analysis = prev.get("analysis", {})
        has_valid_analysis = (
            prev_analysis and
            prev_analysis.get("category") != "unknown" and
            not prev_analysis.get("description", "").startswith("Erreur")
        )
        needs_analysis = (
            not has_valid_analysis or
            prev.get("content_hash") != current_hash
        )

        if needs_analysis and config.get("gemini_api_key"):
            print(f"  🤖 Analyzing with Gemini...")
            context = get_project_context(project_path)
            analysis = analyze_with_gemini(project_name, context, config)
            time.sleep(1.5)  # Rate limiting: éviter 429
        else:
            analysis = prev.get("analysis", {})

        # Construire l'entrée du projet
        project_data = {
            "path": project_path,
            "types": project_types,
            "version": version,
            "git": git_status,
            "analysis": analysis,
            "content_hash": current_hash,
            "last_scan": datetime.now().isoformat(),
        }

        # Détecter les changements
        if prev:
            # Version changée
            if prev.get("version") != version and version:
                changes.append(f"📦 {project_name}: version {prev.get('version')} → {version}")

            # Nouveaux commits non poussés
            prev_git = prev.get("git") or {}
            prev_unpushed = prev_git.get("unpushed_commits", 0)
            curr_unpushed = git_status.get("unpushed_commits", 0) if git_status else 0
            if curr_unpushed > 0 and curr_unpushed != prev_unpushed:
                changes.append(f"⬆️ {project_name}: {curr_unpushed} commit(s) non poussé(s)")

            # Fichiers modifiés
            prev_modified = prev_git.get("modified_files", 0)
            curr_modified = git_status.get("modified_files", 0) if git_status else 0
            if curr_modified > 0 and curr_modified != prev_modified:
                changes.append(f"📝 {project_name}: {curr_modified} fichier(s) modifié(s)")
        else:
            changes.append(f"🆕 Nouveau projet détecté: {project_name}")

        updated[project_name] = project_data

    # Projets supprimés
    for name in existing:
        if name not in updated:
            changes.append(f"🗑️ Projet supprimé: {name}")

    return updated, changes

def main():
    """Point d'entrée principal"""
    print("=" * 60)
    print(f"🔍 Project Tracker - {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print("=" * 60)

    try:
        config = load_config()
    except FileNotFoundError as e:
        print(f"❌ {e}")
        print("Créez un fichier config.json avec:")
        print('  {"projects_directory": "~/Projects", "gemini_api_key": "..."}')
        return

    try:
        projects, changes = scan_projects(config)
        save_projects(projects)
        write_html_report(projects, changes)
        if config.get("open_report", True):
            open_html_report()

        print(f"\n✅ {len(projects)} projet(s) analysé(s)")
        print(f"🧾 Rapport HTML généré: {HTML_REPORT_FILE}")

        if changes:
            print("\n📋 Changements détectés:")
            for change in changes:
                print(f"  {change}")

            # Notification macOS
            if config.get("notifications", True):
                notify(
                    "Project Tracker",
                    f"{len(changes)} changement(s) détecté(s)",
                    sound=True
                )
        else:
            print("\n😴 Aucun changement")

    except Exception as e:
        print(f"❌ Erreur: {e}")
        if config.get("notifications", True):
            notify("Project Tracker", f"Erreur: {str(e)[:50]}", sound=True)
        raise

if __name__ == "__main__":
    main()
