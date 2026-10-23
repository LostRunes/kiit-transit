"""Builds assets/network/network.json from tool/network_data.py.

    python tool/build_network.py            # uses tool/geocode_cache.json
    python tool/build_network.py --refresh  # re-geocode everything

Steps: geocode each Mo Bus stop with MapTiler (cached), reject results that
don't match the name or sit far from their neighbours on a route, interpolate
the rejects, then snap every route to the road network with the public OSRM
demo server. Stops whose position was interpolated are marked approximate.
"""

import json
import math
import os
import re
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(__file__))
import network_data as nd  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tool", "geocode_cache.json")
OUT = os.path.join(ROOT, "assets", "network", "network.json")
def _env_file(path):
    """KEY=value pairs from the repo's .env file (kept out of git)."""
    values = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                values[k.strip()] = v.strip().strip('"').strip("'")
    return values


KEY = os.environ.get("MAPTILER_KEY") or _env_file(os.path.join(ROOT, ".env")).get("MAPTILER_KEY", "")
UA = {"User-Agent": "kiit-transit-build/1.0"}

BBOX = {
    "Bhubaneswar": (85.70, 20.18, 85.95, 20.40),
    "Cuttack": (85.78, 20.36, 85.98, 20.56),
    "Khordha": (85.55, 20.08, 85.80, 20.26),
    "Puri": (85.78, 19.78, 85.92, 20.12),
    "Puri district": (85.80, 19.85, 86.12, 20.16),
}
CENTER = {
    "Bhubaneswar": (85.82, 20.29),
    "Cuttack": (85.88, 20.46),
    "Khordha": (85.65, 20.17),
    "Puri": (85.84, 19.90),
    "Puri district": (85.95, 20.02),
}


def dist(a, b):
    """Metres between (lat, lng) pairs."""
    r = 6371000
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp, dl = p2 - p1, math.radians(b[1] - a[1])
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


STOPWORDS = {"the", "near", "odisha", "india", "square", "sq", "chhak", "road", "station", "bhubaneswar", "cuttack"}


def tokens(s):
    return {t for t in re.findall(r"[a-z0-9]+", s.lower()) if len(t) > 1 and t not in STOPWORDS}


def matches(query, text):
    """True when most of the query's words appear in the result (spacing-insensitive)."""
    want = tokens(query)
    if not want:
        return False
    compact = re.sub(r"[^a-z0-9]", "", text.lower())
    hits = sum(1 for t in want if t in compact)
    return hits >= max(1, math.ceil(len(want) * 0.6))


def geocode(name, area):
    q = re.sub(r"\(.*?\)", "", name).strip()
    url = "https://api.maptiler.com/geocoding/{}.json?{}".format(
        urllib.parse.quote(f"{q}, {area}"),
        urllib.parse.urlencode({
            "key": KEY,
            "bbox": ",".join(map(str, BBOX[area])),
            "proximity": ",".join(map(str, CENTER[area])),
            "limit": 5,
        }),
    )
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        data = json.load(r)
    for f in data.get("features", []):
        text = f.get("text", "") + " " + f.get("place_name", "")
        if matches(q, text):
            lng, lat = f["center"]
            return [lat, lng, f.get("place_name", "")]
    return None


def nominatim(name, area):
    q = re.sub(r"\(.*?\)", "", name).strip()
    x0, y0, x1, y1 = BBOX[area]
    url = "https://nominatim.openstreetmap.org/search?" + urllib.parse.urlencode({
        "q": q, "format": "json", "limit": 5, "viewbox": f"{x0},{y1},{x1},{y0}", "bounded": 1,
    })
    req = urllib.request.Request(url, headers={"User-Agent": "kiit-transit-build/1.0 (student project)"})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.load(r)
    time.sleep(1.1)  # Nominatim usage policy: max 1 request per second
    for e in data:
        if matches(q, e.get("display_name", "")):
            return [float(e["lat"]), float(e["lon"]), e["display_name"]]
    return None


def osrm(points):
    coords = ";".join(f"{lng:.6f},{lat:.6f}" for lat, lng in points)
    url = f"https://router.project-osrm.org/route/v1/driving/{coords}?overview=full&geometries=geojson"
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        data = json.load(r)
    if data.get("code") != "Ok":
        raise RuntimeError(data.get("message", data.get("code")))
    route = data["routes"][0]
    return [[lat, lng] for lng, lat in route["geometry"]["coordinates"]], route["distance"]


def simplify(points, tolerance=12.0):
    """Douglas-Peucker in metres (equirectangular approximation)."""
    if len(points) < 3:
        return points
    lat0 = math.radians(points[0][0])
    xy = [(p[1] * 111320 * math.cos(lat0), p[0] * 110540) for p in points]

    def perp(i, a, b):
        (x, y), (x1, y1), (x2, y2) = xy[i], xy[a], xy[b]
        dx, dy = x2 - x1, y2 - y1
        if dx == dy == 0:
            return math.hypot(x - x1, y - y1)
        return abs(dy * x - dx * y + x2 * y1 - y2 * x1) / math.hypot(dx, dy)

    keep = {0, len(points) - 1}
    stack = [(0, len(points) - 1)]
    while stack:
        a, b = stack.pop()
        best, idx = 0.0, None
        for i in range(a + 1, b):
            d = perp(i, a, b)
            if d > best:
                best, idx = d, i
        if idx is not None and best > tolerance:
            keep.add(idx)
            stack += [(a, idx), (idx, b)]
    return [[round(points[i][0], 5), round(points[i][1], 5)] for i in sorted(keep)]


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def main():
    if not KEY:
        sys.exit("MAPTILER_KEY is missing: copy .env.example to .env and add your key.")
    refresh = "--refresh" in sys.argv
    cache = {} if refresh or not os.path.exists(CACHE) else json.load(open(CACHE, encoding="utf-8"))

    names = []
    for _, _, _, stops in nd.MOBUS_ROUTES:
        for s in stops:
            if s not in names:
                names.append(s)

    # 1. Geocode.
    pos = {}
    for n in names:
        if n in nd.FIXED or n in nd.FIXED_APPROX:
            pos[n] = list(nd.FIXED.get(n) or nd.FIXED_APPROX[n])
            continue
        if n not in cache:
            area = nd.AREA.get(n, "Bhubaneswar")
            try:
                cache[n] = geocode(n, area) or nominatim(n, area)
            except Exception as e:  # network hiccup: retry next run
                print("geocode failed", n, e)
                continue
            time.sleep(0.15)
        if cache[n]:
            pos[n] = cache[n][:2]
    json.dump(cache, open(CACHE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    # 2. Reject outliers. Geocoders happily return a same-named place in the
    #    wrong suburb, so repeatedly drop the single stop that causes the worst
    #    detour on any route (measured against its nearest placed neighbours)
    #    until every route runs reasonably straight between placed stops.
    approx = set(n for n in names if n not in pos) | set(nd.FIXED_APPROX)
    pinned = set(nd.FIXED) | set(nd.FIXED_APPROX)
    while True:
        worst, worst_ex = None, 0.0
        for _, _, _, stops in nd.MOBUS_ROUTES:
            known = [i for i, n in enumerate(stops) if n in pos]
            for k in range(1, len(known) - 1):
                a_, s_, b_ = stops[known[k - 1]], stops[known[k]], stops[known[k + 1]]
                if s_ in pinned:
                    continue
                gap = dist(pos[a_], pos[b_])
                ex = dist(pos[a_], pos[s_]) + dist(pos[s_], pos[b_]) - gap
                limit = max(1200.0, 0.6 * gap)
                if ex > limit and ex - limit > worst_ex:
                    worst, worst_ex = s_, ex - limit
            # Route ends: an end far beyond its neighbour relative to typical spacing.
            for end, nxt in ((0, 1), (len(stops) - 1, len(stops) - 2)):
                e_, n_ = stops[end], stops[nxt]
                if e_ in pos and n_ in pos and e_ not in pinned and dist(pos[e_], pos[n_]) > 6000:
                    if dist(pos[e_], pos[n_]) - 6000 > worst_ex:
                        worst, worst_ex = e_, dist(pos[e_], pos[n_]) - 6000
        if worst is None:
            break
        approx.add(worst)
        pos.pop(worst)

    # 3. Interpolate missing stops between the nearest known neighbours.
    for _ in range(4):
        for _, _, _, stops in nd.MOBUS_ROUTES:
            known = [i for i, s in enumerate(stops) if s in pos]
            for i, s in enumerate(stops):
                if s in pos:
                    continue
                before = [k for k in known if k < i]
                after = [k for k in known if k > i]
                if before and after:
                    a, b = before[-1], after[0]
                    t = (i - a) / (b - a)
                    pa, pb = pos[stops[a]], pos[stops[b]]
                    pos[s] = [pa[0] + (pb[0] - pa[0]) * t, pa[1] + (pb[1] - pa[1]) * t]
    missing = [n for n in names if n not in pos]
    if missing:
        sys.exit(f"Could not place: {missing}")

    # 4. Assemble stops.
    stops_out = []
    for cid, (name, lat, lng, is_approx) in nd.CAMPUSES.items():
        stops_out.append({"id": cid.lower(), "name": name, "lat": lat, "lng": lng, "kind": "campus", "approx": is_approx})
    for n in names:
        stops_out.append({
            "id": slug(n), "name": n, "lat": round(pos[n][0], 6), "lng": round(pos[n][1], 6),
            "kind": "stop", "approx": n in approx,
        })

    # 5. Routes with road geometry.
    routes_out = []
    for rid, mode, path, source in nd.KIIT_ROUTES:
        pts = [nd.CAMPUSES[c][1:3] for c in path]
        routes_out.append({
            "id": "kiit-" + rid.lower(), "ref": rid, "operator": "kiit", "mode": mode,
            "name": " - ".join(nd.CAMPUSES[c][0].split(" (")[0] for c in path),
            "color": "#2D6957" if mode == "bus" else "#E9B949",
            "stops": [c.lower() for c in path], "origin": source.lower(),
            "geometry": road(pts),
        })
        time.sleep(0.3)
    for ref, name, color, path in nd.MOBUS_ROUTES:
        pts = [pos[s] for s in path]
        routes_out.append({
            "id": "mobus-" + ref.lower(), "ref": ref, "operator": "mobus", "mode": "bus", "name": name,
            "color": color, "stops": [slug(s) for s in path], "geometry": road(pts),
        })
        time.sleep(0.5)
        print("route", ref, len(path), "stops")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    meta = {
        "generated": time.strftime("%Y-%m-%d"),
        "sources": {
            "kiit": "Student field research, codedex.io KIIT Transit (2-way links, no timetables)",
            "mobus": "CRUT Mo Bus network map (MO_BUS_Full_Network_Final_1.pdf)",
        },
    }
    json.dump({"meta": meta, "stops": stops_out, "routes": routes_out},
              open(OUT, "w", encoding="utf-8"), separators=(",", ":"), ensure_ascii=False)
    print(f"wrote {OUT}: {len(stops_out)} stops, {len(routes_out)} routes, {len(approx)} approximate stops")
    if approx:
        print("approximate:", ", ".join(sorted(approx)))


def road(points):
    """Road-snapped polyline. If the whole route detours suspiciously (usually one
    badly placed stop), snap leg by leg and keep only the legs that look sane."""
    straight = sum(dist(points[i], points[i + 1]) for i in range(len(points) - 1))
    try:
        line, length = osrm(points)
        if length <= max(2.5 * straight, straight + 1500):
            return simplify(line)
    except Exception as e:
        print("  osrm failed:", e)
    out = [list(points[0])]
    for a, b in zip(points, points[1:]):
        leg = [list(a), list(b)]
        try:
            line, length = osrm([a, b])
            if length <= max(2.5 * dist(a, b), dist(a, b) + 1200):
                leg = line
        except Exception:
            pass
        out += leg[1:]
        time.sleep(0.25)
    return simplify(out)


if __name__ == "__main__":
    main()
