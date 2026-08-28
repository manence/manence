# CLAUDE.md, <nom du projet>

L'identité du système est neutre vis-à-vis de l'agent et vit dans `AGENTS.md`. Ce fichier l'importe, puis ajoute ce qui est propre à Claude Code.

@AGENTS.md

## Câblage Claude Code
- **Le dur vit dans `.claude/`** : `.claude/settings.json` déclare les hooks et les permissions refusées, `.claude/hooks/guard.sh` bloque, `.claude/hooks/lint.sh` rapporte. Une règle écrite en prose ne fait que suggérer ; seuls ceux-là contraignent.
- **Les skills se chargent depuis `.claude/skills/`** — leur domicile unique. Un lien `skills/` à la racine, si le premier démarrage en a posé un, n'est qu'un pont pour un autre agent : on n'y écrit jamais.
