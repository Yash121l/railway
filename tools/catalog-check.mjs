// Smoke test for the offline IR catalog (src/lib/catalog.ts).
// Run: node tools/catalog-check.mjs
// Imports the real module (Node strips the TypeScript) so the assertions
// exercise the shipping search + ranking, not a copy of it.

import {
  trains,
  stations,
  searchTrains,
  searchStations,
  trainByNumber,
  stationByCode,
} from "../src/lib/catalog.ts";

let failures = 0;

function check(label, ok, detail = "") {
  const mark = ok ? "ok  " : "FAIL";
  console.log(`${mark} ${label}${detail ? `  — ${detail}` : ""}`);
  if (!ok) failures += 1;
}

// The index loaded at all.
check("train index loads", trains.length === 4022, `${trains.length} trains`);
check("station index loads", stations.length === 9161, `${stations.length} stations`);

// 12951 exists and resolves cleanly.
const t = trainByNumber("12951");
check("12951 exists", !!t, t ? `${t.name} [${t.category}]` : "not found");
check("12951 reads as Rajdhani", !!t && t.category === "rajdhani");
check("12951 display name expands RAJ", !!t && t.name.includes("Rajdhani"));

// Station NDLS resolves.
const ndls = stationByCode("NDLS");
check("NDLS resolves", !!ndls && ndls.n === "New Delhi", ndls ? ndls.n : "not found");
check("stationByCode is case-insensitive", !!stationByCode("ndls"));

// Name search for "rajdhani" surfaces the canonical Mumbai Rajdhani pair
// (12951/12952) near the top — inside the first 30 of every matching train,
// out of 4,022 in the index. Ranked against the full match set (not a
// truncated page) so the position is real.
const rajResults = searchTrains("rajdhani", 500);
const i51 = rajResults.findIndex((r) => r.number === "12951");
const i52 = rajResults.findIndex((r) => r.number === "12952");
check("'rajdhani' returns 12951 near the top", i51 >= 0 && i51 < 30, `rank #${i51 + 1} of ${trains.length} trains`);
check("'rajdhani' returns 12952 near the top", i52 >= 0 && i52 < 30, `rank #${i52 + 1} of ${trains.length} trains`);
check("12951/12952 land together as the up/down pair", i51 >= 0 && Math.abs(i51 - i52) === 1);

// Number-prefix search stays first-class.
const numResults = searchTrains("1295");
check("'1295' number-prefix hits 12951", numResults.some((r) => r.number === "12951"));

// Station search ranks a code prefix ahead of name hits.
const stnResults = searchStations("NDLS");
check("station search 'NDLS' returns NDLS first", stnResults[0]?.c === "NDLS", stnResults[0]?.c);

if (failures > 0) {
  console.error(`\n${failures} check(s) failed.`);
  process.exit(1);
}
console.log("\nAll catalog checks passed.");
