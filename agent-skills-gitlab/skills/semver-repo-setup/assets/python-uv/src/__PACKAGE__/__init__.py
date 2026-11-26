"""__TITLE__ — __DESCRIPTION__"""

from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("__DIST_NAME__")
except PackageNotFoundError:  # pragma: no cover - paquet non installé
    __version__ = "0.0.0"
