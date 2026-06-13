"""Foundation Models adapter training workflows."""

EXIT_SUCCESS = 0
EXIT_FAILURE = 1
EXIT_USAGE = 2

__version__ = "0.2.0"
__author__ = "Rudrank Riyam"

from .banner import print_banner, BANNER

__all__ = ["print_banner", "BANNER"]
