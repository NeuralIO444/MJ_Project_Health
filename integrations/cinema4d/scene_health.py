# -*- coding: utf-8 -*-
"""
MJ C4D Scene Health — read-only Observer scrape (c4dpy).

Run with Cinema 4D's c4dpy, not system python:

  /Applications/Maxon\\ Cinema\\ 4D\\ */c4dpy.app/Contents/MacOS/c4dpy \\
    scene_health.py /absolute/path/to/shot.c4d [/absolute/out/dir]

Writes MJ_C4D_SCRAPE_1 JSON. Never saves or mutates the project.
"""

from __future__ import annotations

import json
import os
import sys
import datetime

SCRAPER_VERSION = "0.1.0"
SCHEMA = "MJ_C4D_SCRAPE_1"
MAX_ASSETS = 2000


def _iso_now() -> str:
    return datetime.datetime.now().replace(microsecond=0).isoformat()


def _kind_from_name(name: str, path: str) -> str:
    n = (name or path or "").lower()
    for ext, kind in (
        (".exr", "texture"),
        (".png", "texture"),
        (".jpg", "texture"),
        (".jpeg", "texture"),
        (".tif", "texture"),
        (".tiff", "texture"),
        (".hdr", "hdr"),
        (".hdri", "hdr"),
        (".vdb", "cache"),
        (".abc", "xref"),
        (".fbx", "xref"),
        (".c4d", "xref"),
    ):
        if n.endswith(ext):
            return kind
    return "other"


def scrape(doc_path: str) -> dict:
    import c4d  # only available inside c4dpy

    doc_path = os.path.abspath(doc_path)
    if not os.path.isfile(doc_path):
        raise FileNotFoundError(doc_path)

    doc = c4d.documents.LoadDocument(
        doc_path,
        c4d.SCENEFILTER_OBJECTS | c4d.SCENEFILTER_MATERIALS,
        None,
    )
    if doc is None:
        raise RuntimeError("LoadDocument failed: %s" % doc_path)

    assets_out = []
    missing = []
    truncated = False

    try:
        asset_list = []
        # GetAllAssetsNew(doc, allowDialogs, lastPath, flags, assetList)
        flags = getattr(c4d, "ASSETDATA_FLAG_0", 0)
        res = c4d.documents.GetAllAssetsNew(
            doc, False, "", flags, asset_list
        )
        # asset_list entries are dict-like in Python API examples
        for i, entry in enumerate(asset_list):
            if i >= MAX_ASSETS:
                truncated = True
                break
            if not isinstance(entry, dict):
                # some builds return objects with attributes
                name = str(getattr(entry, "assetname", getattr(entry, "name", "?")))
                path = str(getattr(entry, "filename", getattr(entry, "path", "")) or "")
                exists = bool(getattr(entry, "exists", os.path.isfile(path) if path else False))
            else:
                name = str(entry.get("assetname") or entry.get("name") or "?")
                path = str(entry.get("filename") or entry.get("path") or "")
                exists = bool(entry.get("exists", os.path.isfile(path) if path else False))
            if path and not exists:
                exists = os.path.isfile(path)
            size = None
            if path and exists:
                try:
                    size = os.path.getsize(path)
                except OSError:
                    size = None
            rec = {
                "name": name,
                "path": path,
                "exists": exists,
                "kind": _kind_from_name(name, path),
                "sizeBytes": size,
            }
            assets_out.append(rec)
            if not exists:
                missing.append(name if name != "?" else (path or "unknown"))
    except Exception as e:
        # Fail soft: still emit a receipt with the error in notes
        return {
            "schema": SCHEMA,
            "scraperVersion": SCRAPER_VERSION,
            "projectPath": doc_path,
            "projectName": os.path.basename(doc_path),
            "scrapedAt": _iso_now(),
            "c4dVersion": str(getattr(c4d, "GetC4DVersion", lambda: "")() or ""),
            "assets": [],
            "assetsMissing": [],
            "numAssets": 0,
            "numMissing": 0,
            "sourceUnchanged": True,
            "notes": "GetAllAssetsNew failed: %s" % str(e)[:200],
        }

    ver = ""
    try:
        ver = str(c4d.GetC4DVersion())
    except Exception:
        ver = ""

    return {
        "schema": SCHEMA,
        "scraperVersion": SCRAPER_VERSION,
        "projectPath": doc_path,
        "projectName": os.path.basename(doc_path),
        "scrapedAt": _iso_now(),
        "c4dVersion": ver,
        "assets": assets_out,
        "assetsMissing": sorted(set(missing)),
        "numAssets": len(assets_out),
        "numMissing": len(set(missing)),
        "assetsTruncated": truncated,
        "sourceUnchanged": True,
    }


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        sys.stderr.write(
            "Usage: c4dpy scene_health.py /abs/path/scene.c4d [/abs/out/dir]\n"
        )
        return 2
    doc_path = argv[1]
    out_dir = argv[2] if len(argv) > 2 else os.path.dirname(os.path.abspath(doc_path))
    os.makedirs(out_dir, exist_ok=True)
    data = scrape(doc_path)
    base = os.path.splitext(os.path.basename(doc_path))[0]
    out_path = os.path.join(out_dir, base + ".MJ_C4D_SCRAPE_1.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    sys.stdout.write(out_path + "\n")
    sys.stdout.write("numMissing=%s numAssets=%s\n" % (data.get("numMissing"), data.get("numAssets")))
    return 0


if __name__ == "__main__":
    # When not under c4dpy, still allow --help schema dry-run
    if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)
    try:
        import c4d  # noqa: F401
    except ImportError:
        sys.stderr.write(
            "This script must run under c4dpy (Cinema 4D Python), not system Python.\n"
        )
        sys.exit(69)
    sys.exit(main(sys.argv))
