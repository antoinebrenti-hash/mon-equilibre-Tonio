# Mon Équilibre — mise en ligne sur GitHub Pages

Ce dossier contient l'application prête à publier. Une fois en ligne, ouvre le lien
dans **Safari sur ton iPhone** → **Partager** ⬆️ → **« Sur l'écran d'accueil »**.

Fichiers (ne rien renommer) :
- `index.html` — l'application
- `manifest.webmanifest` — réglages « app »
- `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` — icônes

---

## Méthode A — sans ligne de commande (le plus simple)

1. Va sur https://github.com/new et crée un dépôt **public**, par ex. `mon-equilibre`.
2. Sur la page du dépôt : **Add file → Upload files**.
3. **Glisse les 5 fichiers** de ce dossier, puis **Commit changes**.
4. Onglet **Settings → Pages**.
5. Sous **Build and deployment → Source**, choisis **Deploy from a branch**,
   branche **main**, dossier **/ (root)**, puis **Save**.
6. Attends ~1 minute, recharge la page : ton lien apparaît, du type
   **`https://TON-NOM.github.io/mon-equilibre/`**.
7. Ouvre ce lien dans **Safari** sur l'iPhone → **Partager** → **« Sur l'écran d'accueil »**.

## Méthode B — avec Git (si tu préfères)

```bash
cd "mon-equilibre-github"
git init
git add .
git commit -m "Mon Équilibre"
git branch -M main
git remote add origin https://github.com/TON-NOM/mon-equilibre.git
git push -u origin main
```

Puis **Settings → Pages** comme aux étapes 4–6 ci-dessus.

---

## Ce qui marche sur cette version hébergée par toi
- ✅ **Compositeur de plats maison** (catalogue d'ingrédients — sel/poivre ≈ 0 kcal),
  recettes réutilisables.
- ✅ **Recherche d'aliments par nom** (Open Food Facts) — plus besoin de code-barres.
- ✅ Sur navigateurs compatibles, **scan de code-barres** par la caméra.
- ✅ Calories/macros/eau, poids + tour de taille + graphiques, programmes d'exercices,
  « Que manger ? », bilan hebdo, export CSV/JSON.
- ✅ **Données 100 % locales** (sur ton téléphone), rien envoyé sur un serveur.

## À savoir
- ❌ **Photo d'un plat → calories** : pas dans cette version (une IA de vision, payante,
  ne donnerait qu'une estimation approximative). Le compositeur d'ingrédients est plus fiable.
- ❌ **Apple Santé** (pas, calories actives) : inaccessible depuis une page web.
- 📷 Le scan caméra dépend du navigateur ; sur iPhone/Safari, utilise plutôt la
  **recherche par nom** ou le **compositeur d'ingrédients**.
- 💾 Sauvegarde de temps en temps via **Progrès → Export JSON**.

Pour mettre à jour l'app plus tard : remplace `index.html` sur GitHub (les données
sur ton téléphone sont conservées, car elles ne sont pas dans le fichier).
