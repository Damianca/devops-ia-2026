from pathlib import Path
from html.parser import HTMLParser
import os
import re

source = Path("app/index.html").read_text(encoding="utf-8")
required = ["<!DOCTYPE html>", "<html", "<title>",
            "<h1>", "</html>", "__COMMIT__"]
for token in required:
    if token not in source:
        raise SystemExit(f"Falta contenido requerido: {token}")
# Es una comprobacion basica; HTMLParser no es un validador HTML.
HTMLParser().feed(source)
sha = os.environ["GITHUB_SHA"]
if not re.fullmatch(r"[0-9a-f]{40}", sha):
    raise SystemExit("GITHUB_SHA no es un SHA completo")
output = Path("dist")
output.mkdir(exist_ok=True)
(output / "index.html").write_text(
    source.replace("__COMMIT__", sha), encoding="utf-8"
)
print(f"Artefacto generado para {sha}")

