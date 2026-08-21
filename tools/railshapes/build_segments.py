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


_LIVE_MIRRORS = None


def live_mirrors():
    """MIRRORS that actually resolve and answer, probed once per run.

    Two of the three public mirrors do not resolve from some networks. The
    retry loop used to spend a third of its attempts on them and sleep 3-15s
    after each, so a leg could burn a minute failing on DNS before it ever
    reached a working mirror. That is what produced most of the
    "nodename nor servname provided" misses in coverage.txt.
    """
    global _LIVE_MIRRORS
    if _LIVE_MIRRORS is not None:
        return _LIVE_MIRRORS
    probe = urllib.parse.urlencode({"data": "[out:json];node(1);out;"}).encode()
    live = []
    for m in MIRRORS:
        try:
            req = urllib.request.Request(
                m, data=probe, headers={"User-Agent": "railly-railshapes/1.0"})
            with urllib.request.urlopen(req, timeout=15):
                pass
            live.append(m)
        except Exception as ex:                       # noqa: BLE001
            print(f"mirror unavailable, skipping: {m} ({ex})", flush=True)
    if not live:
        live = list(MIRRORS)
        print("no mirror answered the probe; trying all anyway", flush=True)
    print(f"using {len(live)}/{len(MIRRORS)} overpass mirror(s)", flush=True)
    _LIVE_MIRRORS = live
    return live


def _is_unresolvable(ex):
    """DNS/name-resolution failure: another 3s of waiting will not help."""
    return "nodename nor servname" in str(ex) or "Name or service not known" in str(ex)


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
    mirrors = live_mirrors()
    last = None
    for attempt in range(6):
        mirror = mirrors[attempt % len(mirrors)]
        try:
            req = urllib.request.Request(
                mirror, data=body,
                headers={"User-Agent": "railly-railshapes/1.0"})
            with urllib.request.urlopen(req, timeout=180) as r:
                data = json.loads(r.read().decode("utf-8", "ignore"))
            os.makedirs(CACHE, exist_ok=True)
            with open(path, "w") as f:
                json.dump(data, f)
            # Overpass is a donated public service; pace new fetches.
            time.sleep(2)
            return data
        except Exception as ex:                       # noqa: BLE001
            last = ex
            if _is_unresolvable(ex):
                continue
            # 504s and rate limits do benefit from waiting.
            time.sleep(5 * (attempt + 1))
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


def snap_pair(g, nodes, pa, pb, max_km=6.0):
    """Snap both halts into the same connected component.

    Snapping each halt to its globally nearest node lands it on whatever rail
    fragment happens to be closest, which around a station is very often a yard
    siding or a stub that is not connected to the through line inside this bbox.
    Dijkstra then reports "no path" across a corridor that is actually
    continuous — that was four of the eight remaining misses, all of them short
    legs on busy main lines.

    So pick the component that holds a usable node for *both* ends and
    minimises the combined snap distance. Ranking uses squared degrees (cheap)
    and only the winner per component pays for a haversine.
    """
    best = None
    for comp in nx.connected_components(g):
        da = db = 1e18
        na = nb = None
        for n in comp:
            c = nodes[n]
            d1 = (c[0] - pa[0]) ** 2 + (c[1] - pa[1]) ** 2
            if d1 < da:
                da, na = d1, n
            d2 = (c[0] - pb[0]) ** 2 + (c[1] - pb[1]) ** 2
            if d2 < db:
                db, nb = d2, n
        if na is None or nb is None:
            continue
        ka = haversine_km(nodes[na], pa)
        kb = haversine_km(nodes[nb], pb)
        if ka > max_km or kb > max_km:
            continue
        if best is None or ka + kb < best[0]:
            best = (ka + kb, na, nb)
    if best is None:
        return None, None
    return best[1], best[2]


def _route_once(pa, pb, pad):
    bbox = (min(pa[0], pb[0]) - pad, min(pa[1], pb[1]) - pad,
            max(pa[0], pb[0]) + pad, max(pa[1], pb[1]) + pad)
    data = overpass(bbox)
    g, nodes = build_graph(data)
    if not nodes:
        return None, "no rail in bbox", 0.0
    sa, sb = snap_pair(g, nodes, pa, pb)
    if sa is None:
        return None, "no component within 6km of both halts", 0.0
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

    chord_km = haversine_km(pa, pb)
    # A leg cannot be shorter than the straight line between its endpoints, so a
    # feed figure below the chord is wrong and must not be used as the
    # reference. GTL>AD claims 34km across a 50km chord; gating on it rejected
    # every candidate route no matter how good.
    # Real track distance can never be less than the straight line between the
    # endpoints, so clamp the reference up to the chord rather than trusting a
    # feed figure below it. GTL>AD claims 34km across a 50km chord; gating on
    # that rejected every candidate route however good. Clamping keeps a
    # corridor guard for the leg instead of dropping it entirely.
    feed_km = expected_km
    if feed_km is not None and feed_km < chord_km:
        print(f"    feed says {feed_km:.0f}km for a {chord_km:.0f}km chord; "
              f"clamping the reference up to the chord", flush=True)
        feed_km = chord_km

    def acceptable(length):
        return feed_km is None or length <= feed_km * LEG_TOLERANCE

    poly, note, length = _route_once(pa, pb, BBOX_PAD_DEG)
    if poly is not None and acceptable(length):
        return poly, note
    tight_note = note if poly is None else (
        f"{length:.0f}km vs feed {feed_km:.0f}km — wrong corridor"
        if feed_km is not None else f"{length:.0f}km, no usable feed distance")

    poly2, note2, length2 = _route_once(pa, pb, 0.55)
    if poly2 is not None and acceptable(length2):
        return poly2, note2 + " (widened)"

    if poly2 is not None:
        if feed_km is None:
            return None, f"widened still {length2:.0f}km vs chord {chord_km:.0f}km"
        return None, (f"widened still {length2:.0f}km vs feed "
                      f"{feed_km:.0f}km — corridor mismatch")
    return None, f"{tight_note}; widened: {note2}"


def write_segments(segments):
    """Publish the library to both bundles that read it, atomically.

    This is called after every routed leg, so it runs ~100 times a run. Writing
    in place truncated both shipped files first, which meant a Ctrl-C or a crash
    mid-dump left the app and the web map with unparseable JSON — and even a
    clean interrupt left them holding a partial library that silently degrades
    routes to straight chords. Write a sibling temp file and rename, which is
    atomic on the same filesystem, so readers only ever see a complete library.
    """
    blob = json.dumps(segments, separators=(",", ":"))
    for path in (OUT, OUT_WEB):
        tmp = f"{path}.tmp"
        with open(tmp, "w") as f:
            f.write(blob)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)


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
    print(f"\nWROTE {ok}/{len(todo)} segments to:\n  {OUT}\n  {OUT_WEB}\nReport → {REPORT}", flush=True)


if __name__ == "__main__":
    main()
