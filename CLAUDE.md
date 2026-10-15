# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This repo is the Streamlit "blank app template" — a minimal starting point for a Streamlit app, not yet built out into a real project. The entire application is `streamlit_app.py`, a single-page script using `streamlit` (aliased `st`).

## Commands

Install dependencies:
```
pip install -r requirements.txt
```

Run the app locally:
```
streamlit run streamlit_app.py
```

There is no lint, test, or build tooling configured in this repo (no test framework, linter, or CI workflow present). If you add one, document the commands here.

## Architecture

- `streamlit_app.py` — the entire app. Streamlit apps are just top-to-bottom Python scripts: each `st.*` call renders a widget/element in order, and the whole script re-runs on every user interaction. There's no routing or component framework beyond what Streamlit itself provides.
- `requirements.txt` — Python dependencies (currently just `streamlit`).
- `.devcontainer/devcontainer.json` — GitHub Codespaces/VS Code devcontainer config. It installs `requirements.txt` and auto-starts the app via `streamlit run streamlit_app.py --server.enableCORS false --server.enableXsrfProtection false`, forwarding port 8501.

As the app grows beyond a single file, Streamlit's convention is to add a `pages/` directory for multi-page apps — check for one before assuming everything belongs in `streamlit_app.py`.
