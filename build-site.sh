#!/usr/bin/env bash
# Copies every notes *.md file (+ site assets) into docs/, preserving structure.
# Run before `mkdocs build`, `mkdocs serve`, or `mkdocs gh-deploy`.
# docs/ and site/ are generated — never commit them (see .gitignore).
set -euo pipefail
cd "$(dirname "$0")"

rm -rf docs site
mkdir -p docs

# All notes, same relative paths (README.md files double as MkDocs index pages).
# SUMMARY.md is GitBook-only and stays out of the site.
find . \
  -name '*.md' -not -name 'SUMMARY.md' \
  -not -path './docs/*' -not -path './site/*' -not -path './.git/*' \
  -exec cp --parents {} docs/ \;

# Site assets (Mermaid initializer, etc.)
mkdir -p docs/javascripts
cp javascripts/mermaid.js docs/javascripts/

echo "Staged $(find docs -name '*.md' | wc -l) pages into docs/"