"""Application FastAPI."""

from fastapi import FastAPI

from __PACKAGE__ import __version__

app = FastAPI(title="__TITLE__", version=__version__, description="__DESCRIPTION__")


@app.get("/health", tags=["ops"])
def health() -> dict[str, str]:
    """Sonde de vivacité : état et version déployée."""
    return {"status": "ok", "version": __version__}
