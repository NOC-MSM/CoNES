# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Imports -----------------------------------------------------------------

import os
import sys

import sphinx_autosummary_accessors
import sphinx_rtd_theme  # noqa: F401

# isort: off

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
sys.path.insert(0, os.path.abspath("../"))

# The master toctree document.
master_doc = 'index'

# -- Project information -----------------------------------------------------

project = "CoNES"
copyright = "2021, eCSE"
author = "James Harle"


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.viewcode",
    "sphinx.ext.extlinks",
    "sphinx.ext.intersphinx",
    "sphinx_rtd_theme",
    "numpydoc",
    "sphinx_autosummary_accessors",
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates", sphinx_autosummary_accessors.templates_path]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# Do not show typehints, only defaults.
# Darglint is already forcing us to have consistent types in the docstring.
autodoc_typehints = "none"

# Do not warn about missing "Methods" in class docstring
numpydoc_show_class_members = False

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["_static"]
html_css_files = ['custom.css']

# Logos
html_logo = "_static/cones_logo.png"
html_favicon = "cones_favicon.png"
html_theme_options = {
    "style_nav_header_background": "#343131",
}

# -- Custom lexer ---------------------------------------------------------

#sys.path.append(os.path.join(os.path.dirname(__file__), '.'))
from sphinx.highlighting import lexers
from pygments_singularity import SingularityLexer
#from pygments_json import JSONLexer
# from replacements import *
# lexer for Singularity definition files (added here until it is upstreamed into Pygments).
lexers['singularity'] = SingularityLexer(startinline=True)
#lexers['json'] = JSONLexer(startinline=True)
