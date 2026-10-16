"""Public catalogue/page retrieval; only saves data and never executes site code."""
from html.parser import HTMLParser
from pathlib import Path
import json
import requests

ROOT = Path(__file__).resolve().parent
EVIDENCE = ROOT / "evidence"
EVIDENCE.mkdir(parents=True, exist_ok=True)


class Page(HTMLParser):
    def __init__(self, data):
        super().__init__()
        self.skip = 0
        self.parts = []
        self.links = []
        self.images = []
        self.current = None
        self.feed(data)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in ("script", "style"):
            self.skip += 1
        if not self.skip and tag == "a":
            self.current = [a.get("href", ""), ""]
        if not self.skip and tag == "img":
            self.images.append(a)

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self.skip = max(0, self.skip - 1)
        if not self.skip and tag == "a" and self.current:
            self.links.append(self.current)
            self.current = None

    def handle_data(self, data):
        if not self.skip:
            self.parts.append(data.strip())
            if self.current:
                self.current[1] += data.strip() + " "

    @property
    def text(self):
        return " ".join(p for p in self.parts if p)


def fetch(name, url, params=None):
    path = EVIDENCE / (name + ".txt")
    if path.exists():
        return path.read_text(encoding="utf8")
    r = requests.get(url, params=params, headers={"User-Agent": "GameMakeAssetResearch/1.0"}, timeout=25)
    r.raise_for_status()
    path.write_text(r.text, encoding="utf8")
    (EVIDENCE / (name + "_request.json")).write_text(json.dumps({"url": r.url, "status": r.status_code}, indent=2), encoding="utf8")
    return r.text
