#!/usr/bin/env python3
"""Build real rail-track polylines for Railly's map, straight from OpenStreetMap.

erail (and every other IR schedule feed) only returns a train's *halts*, so a
straight line between two far-apart coastal halts chords across open water. This
script derives the actual track shape between consecutive halts from OSM
(railway=rail ways, routed as a graph) and bundles the simplified polylines as a
segment library keyed by "FROM>TO" station-code pairs. The app splices these in;
any pair we can't route falls back to a straight chord.

Authoring-time only — not shipped or run on device. Re-runnable: raw Overpass
responses are cached under tools/railshapes/cache/ so reruns are cheap.

    python3 build_segments.py            # route pairs >= MIN_KM
    python3 build_segments.py --all      # route every pair regardless of length
"""
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SEED = os.path.join(REPO, "ios/Railly/Resources/SeedTrains.json")
# The iOS app and the web map read the same segment library from their own
# bundles, so every run writes both — a stale copy silently degrades one of
# them back to straight-line chords.
OUT = os.path.join(REPO, "ios/Railly/Resources/RailSegments.json")
OUT_WEB = os.path.join(REPO, "src/data/rail-segments.json")
CACHE = os.path.join(HERE, "cache")
REPORT = os.path.join(HERE, "coverage.txt")

# Short hops render fine as straight lines; only route legs long enough to
# actually diverge from a chord (this is where ocean-crossings happen).
MIN_KM = 20.0
BBOX_PAD_DEG = 0.18           # ~20 km padding around the halt-pair bbox
RDP_EPS_DEG = 0.0025          # ~275 m simplification tolerance
COORD_DP = 5                  # ~1 m coordinate precision in the bundle

# erail rejects unfamiliar clients; mirror the app's own header.
UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15"

MIRRORS = [
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass-api.de/api/interpreter",
]

try:
    import networkx as nx
except ImportError:
    sys.exit("networkx missing — `pip install networkx requests` in the venv first")


def haversine_km(a, b):
    R = 6371.0
    dlat = math.radians(b[0] - a[0])
    dlng = math.radians(b[1] - a[1])
    h = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(a[0])) * math.cos(math.radians(b[0])) * math.sin(dlng / 2) ** 2)
    return 2 * R * math.asin(math.sqrt(h))


def rdp(points, eps):
    """Ramer–Douglas–Peucker on (lat,lng) points, tolerance in degrees."""
    if len(points) < 3:
        return points
    start, end = points[0], points[-1]
    dmax, idx = 0.0, 0
    for i in range(1, len(points) - 1):
        d = _perp(points[i], start, end)
        if d > dmax:
            dmax, idx = d, i
    if dmax > eps:
        left = rdp(points[:idx + 1], eps)
        right = rdp(points[idx:], eps)
        return left[:-1] + right
    return [start, end]


def _perp(p, a, b):
    if a == b:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    num = abs((b[0] - a[0]) * (a[1] - p[1]) - (a[0] - p[0]) * (b[1] - a[1]))
    den = math.hypot(b[0] - a[0], b[1] - a[1])
    return num / den


def real_leg_km(trains):
    """Real track km for every consecutive halt pair, from erail's own route.

    TRAINROUTE field 6 is the halt's cumulative track distance from the origin,
    so the difference between two halts is the true length of that leg. Without
    it the only sanity check available is "not wildly longer than the straight
    chord", which is far too loose: the Kota->New Delhi leg routed 544 km via
    *Jaipur* instead of 464 km via Bharatpur/Mathura — a different corridor
    entirely, and only 1.35x the chord, so it passed unnoticed."""
    path = os.path.join(CACHE, "legkm.json")
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)

    out = {}
    for t in trains:
        url = ("https://erail.in/data.aspx?Action=TRAINROUTE&Password=2012"
               f"&Data1={t['trainId']}&Data2=0&Cache=true")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=25) as r:
                text = r.read().decode("utf-8", "ignore")
        except Exception as ex:                        # noqa: BLE001
            print(f"  legkm: {t['number']} unavailable ({ex})", flush=True)
            continue
        km = {}
        for row in text.split("^"):
            f = row.split("~")
            if len(f) <= 17:
                continue
            try:
                km[f[1].strip()] = float(f[6])
            except ValueError:
                pass
        for s1, s2 in zip(t["stops"], t["stops"][1:]):
            c1, c2 = s1["code"], s2["code"]
            if c1 in km and c2 in km:
                out[f"{c1}>{c2}"] = abs(km[c2] - km[c1])
        time.sleep(0.4)

    os.makedirs(CACHE, exist_ok=True)
    with open(path, "w") as f:
        json.dump(out, f)
    print(f"real leg distances for {len(out)} pairs (cached)", flush=True)
    return out


def overpass(bbox):
    """Fetch rail ways (geometry inline) for a bbox; cache raw JSON on disk.

    `out geom` skips the expensive node-recursion — the response is far
    smaller/faster; connectivity is recovered from shared coordinates."""
    s, w, n, e = bbox
    key = f"geom_{s:.3f}_{w:.3f}_{n:.3f}_{e:.3f}.json"
    path = os.path.join(CACHE, key)
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    query = (f"[out:json][timeout:90];"
             f'way["railway"="rail"]({s},{w},{n},{e});'
             f"out geom;")
    body = urllib.parse.urlencode({"data": query}).encode()
    last = None
    for attempt in range(6):
        mirror = MIRRORS[attempt % len(MIRRORS)]
        try:
            req = urllib.request.Request(
                mirror, data=body,
                headers={"User-Agent": "railly-railshapes/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = json.loads(r.read().decode("utf-8", "ignore"))
            os.makedirs(CACHE, exist_ok=True)
            with open(path, "w") as f:
                json.dump(data, f)
            return data
        except Exception as ex:                       # noqa: BLE001
            last = ex
            time.sleep(3 * (attempt + 1))
    raise RuntimeError(f"overpass failed for {bbox}: {last}")


def build_graph(data):
    """Graph keyed by rounded coordinate — OSM ways that meet at a junction
    share a node with identical coords, so rounded keys reconnect them."""
    g = nx.Graph()
    nodes = {}
    for el in data["elements"]:
        if el["type"] != "way":
            continue
        prev = None
        for pt in el.get("geometry") or []:
            k = (round(pt["lat"], 7), round(pt["lon"], 7))
            nodes[k] = (pt["lat"], pt["lon"])
            if prev is not None and prev != k:
                g.add_edge(prev, k, w=haversine_km(nodes[prev], nodes[k]))
            prev = k
    return g, nodes


def nearest(nodes, pt):
    best, bd = None, 1e9
    for nid, c in nodes.items():
        d = (c[0] - pt[0]) ** 2 + (c[1] - pt[1]) ** 2
        if d < bd:
            bd, best = d, nid
    return best


def _route_once(pa, pb, pad):
    bbox = (min(pa[0], pb[0]) - pad, min(pa[1], pb[1]) - pad,
            max(pa[0], pb[0]) + pad, max(pa[1], pb[1]) + pad)
    data = overpass(bbox)
    g, nodes = build_graph(data)
    if not nodes:
        return None, "no rail in bbox", 0.0
    sa, sb = nearest(nodes, pa), nearest(nodes, pb)
    # snapped nodes must land near the actual halt, else it's the wrong line
    if haversine_km(nodes[sa], pa) > 6 or haversine_km(nodes[sb], pb) > 6:
        return None, "halt too far from rail", 0.0
    try:
        path = nx.shortest_path(g, sa, sb, weight="w")
    except (nx.NetworkXNoPath, nx.NodeNotFound):
        return None, "no path", 0.0
    coords = [nodes[n] for n in path]
    # sanity: routed length shouldn't wildly exceed the straight chord
    chord = haversine_km(pa, pb)
    length = sum(haversine_km(coords[i - 1], coords[i]) for i in range(1, len(coords)))
    if chord > 1 and length > chord * 2.2:
        return None, f"route {length:.0f}km >> chord {chord:.0f}km", 0.0
    simplified = rdp([(round(c[0], COORD_DP), round(c[1], COORD_DP)) for c in coords], RDP_EPS_DEG)
    return [[c[0], c[1]] for c in simplified], f"{length:.0f}km {len(simplified)}pts", length


# A routed leg may exceed the feed's own distance a little (OSM traces every
# curve the timetable rounds off), but not by much. Beyond this it isn't the
# same corridor.
LEG_TOLERANCE = 1.12


def route_pair(a, b, expected_km=None):
    """a,b are (code,(lat,lng)); return simplified [[lat,lng],...] or None.

    Tries a tight bbox first (fast, cache-friendly), then widens. A tight bbox
    fails in two ways: it can clip the graph so *no* path is found, or — worse,
    because it looks like success — it can leave only a path down a completely
    different corridor. Kota->New Delhi did exactly that: Bharatpur (77.49E)
    and Mathura (77.67E) fell outside the 77.40E edge, so the only connected
    route was the western one via Jaipur, 544 km against the timetable's 464.
    So a leg is accepted only if its length matches what the feed says that leg
    actually is; otherwise we widen, and failing that we take the straight-line
    fallback rather than draw a confident line through the wrong cities."""
    (_, pa), (_, pb) = a, b

    def acceptable(length):
        return expected_km is None or length <= expected_km * LEG_TOLERANCE

    poly, note, length = _route_once(pa, pb, BBOX_PAD_DEG)
    if poly is not None and acceptable(length):
        return poly, note
    tight_note = note if poly is None else (
        f"{length:.0f}km vs feed {expected_km:.0f}km — wrong corridor")

    poly2, note2, length2 = _route_once(pa, pb, 0.55)
    if poly2 is not None and acceptable(length2):
        return poly2, note2 + " (widened)"

    if poly2 is not None:
        return None, (f"widened still {length2:.0f}km vs feed "
                      f"{expected_km:.0f}km — corridor mismatch")
    return None, f"{tight_note}; widened: {note2}"


def write_segments(segments):
    """Publish the library to both bundles that read it."""
    for path in (OUT, OUT_WEB):
        with open(path, "w") as f:
            json.dump(segments, f, separators=(",", ":"))


def main():
    route_all = "--all" in sys.argv
    trains = json.load(open(SEED))
    pairs = {}          # "FROM>TO" -> ((code,(lat,lng)),(code,(lat,lng)))
    for t in trains:
        for s1, s2 in zip(t["stops"], t["stops"][1:]):
            key = f'{s1["code"]}>{s2["code"]}'
            rkey = f'{s2["code"]}>{s1["code"]}'
            if key in pairs or rkey in pairs:
                continue
            pairs[key] = ((s1["code"], (s1["lat"], s1["lng"])),
                          (s2["code"], (s2["lat"], s2["lng"])))

    todo = []
    skipped_short = 0
    for key, (a, b) in pairs.items():
        if route_all or haversine_km(a[1], b[1]) >= MIN_KM:
            todo.append((key, a, b))
        else:
            skipped_short += 1
    # Longest legs first — that's where chords cross water, so the visible
    # ocean-crossings (BZA>MAS across the Bay of Bengal, etc.) land first.
    todo.sort(key=lambda t: -haversine_km(t[1][1], t[2][1]))

    print(f"{len(pairs)} unique pairs · routing {len(todo)} "
          f"(skipped {skipped_short} short <{MIN_KM}km) · --all={route_all}", flush=True)

    # Ground truth for "is this actually the leg the train runs?"
    expected = real_leg_km(trains)

    segments, report = {}, []
    for i, (key, a, b) in enumerate(todo, 1):
        exp = expected.get(key) or expected.get(f"{b[0]}>{a[0]}")
        try:
            poly, note = route_pair(a, b, exp)
        except Exception as ex:                        # noqa: BLE001
            poly, note = None, f"error: {ex}"
        if poly:
            segments[key] = poly
            report.append(f"OK   {key:14} {note}")
            # flush incrementally so the app can be rebuilt with partial results
            write_segments(segments)
        else:
            report.append(f"MISS {key:14} {note}  (straight-line fallback)")
        print(f"[{i}/{len(todo)}] {key}: {'ok' if poly else 'miss'} — {note}", flush=True)

    write_segments(segments)
    ok = len(segments)
    with open(REPORT, "w") as f:
        f.write(f"routed {ok}/{len(todo)} pairs, {skipped_short} short skipped\n\n"
                + "\n".join(sorted(report)))
    print(f"\nWROTE {OUT}: {ok}/{len(todo)} segments. Report → {REPORT}", flush=True)


if __name__ == "__main__":
    main()
