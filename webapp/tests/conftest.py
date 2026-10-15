"""Configura o sys.path para importar ``core``/``ui`` nos testes."""

import os
import sys

WEBAPP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if WEBAPP_DIR not in sys.path:
    sys.path.insert(0, WEBAPP_DIR)
