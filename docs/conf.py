# Sphinx configuration for the Athar documentation.
# Build: python -m sphinx -b html docs docs/_build/html

project = "Athar (أثر)"
author = "Athar team"
copyright = "2026, Athar team"
release = "1.0.0"

extensions = []
templates_path = []
exclude_patterns = ["_build"]

html_theme = "alabaster"
html_title = "Athar documentation"
html_theme_options = {
    "description": "Take back your time: screen-time habits, OTP sign-in and AI reports.",
    "fixed_sidebar": True,
    "page_width": "1100px",
    "sidebar_width": "240px",
}
