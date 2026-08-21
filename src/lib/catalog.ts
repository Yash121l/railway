import type { TrainCategory } from "./types";
import trainIndex from "../data/ir-trains.json" with { type: "json" };
import stationIndex from "../data/stations.json" with { type: "json" };

/**
 * Bundled offline index of the real IR network — every train and station,
 * straight from erail's own lookup assets: 4,022 trains, and 9,161 station
 * rows carrying 9,109 distinct codes (tourist names alias to a railhead).
 * Search runs instantly in-process; the network is only touched when a
 * specific train's schedule is needed. This is the web port of
 * ios/Railly/Catalog.swift and keeps its Flighty ranking semantics.
 */

/** A raw station index row: `c` = station code, `n` = station name. */
export interface CatalogStation {
  /** station code */
  c: string;
  /** station name */
  n: string;
}

export interface CatalogTrain {
  number: string;
  /** erail's ALL-CAPS, clipped name ("NDLS TEJAS RAJ") */
  rawName: string;
  /** expanded, title-cased name for display ("NDLS Tejas Rajdhani") */
  name: string;
  category: TrainCategory;
}

const TRAIN_INDEX = trainIndex as readonly string[];
const STATION_INDEX = stationIndex as readonly CatalogStation[];

export const stations: readonly CatalogStation[] = STATION_INDEX;

export const stationCodes: ReadonlySet<string> = new Set(
  stations.map((s) => s.c),
);

const stationByCodeMap = new Map(stations.map((s) => [s.c, s]));

/**
 * erail names arrive ALL-CAPS and clipped ("NDLS TEJAS RAJ", "BKN DURONTO
 * EXP"). Expand the standard railway abbreviations, keep station codes as
 * codes, and title-case the rest.
 */
const nameExpansions: Record<string, string> = {
  EXP: "Express",
  EXPRES: "Express",
  EXPRESS: "Express",
  SF: "Superfast",
  SUP: "Superfast",
  SPL: "Special",
  SPECIA: "Special",
  PASS: "Passenger",
  PASSNG: "Passenger",
  RAJ: "Rajdhani",
  RAJDHN: "Rajdhani",
  SHTBDI: "Shatabdi",
  SHATAB: "Shatabdi",
  JANSHT: "Jan Shatabdi",
  JSHTBD: "Jan Shatabdi",
  VB: "Vande Bharat",
  INT: "Intercity",
  INTERC: "Intercity",
  GARIBRATH: "Garib Rath",
  GRATH: "Garib Rath",
  G: "Garib",
  AC: "AC",
  MEMU: "MEMU",
  EMU: "EMU",
  DEMU: "DEMU",
  JN: "Jn",
  TERM: "Terminus",
};

export function prettyTrainName(raw: string): string {
  return raw
    .split(" ")
    .filter((w) => w.length > 0)
    .map((word) => {
      const expanded = nameExpansions[word];
      if (expanded) return expanded;
      // station codes stay as codes ("NDLS Tejas Rajdhani")
      if (word.length <= 5 && stationCodes.has(word)) return word;
      if (word.length <= 2) return word;
      return word[0] + word.slice(1).toLowerCase();
    })
    .join(" ");
}

export function categoryFor(name: string, type = ""): TrainCategory {
  const n = name.toUpperCase();
  const t = type.toUpperCase();
  if (n.includes("VANDE BHARAT")) return "vande-bharat";
  if (t.includes("RAJDHANI") || n.includes("RAJDHANI") || n.endsWith(" RAJ"))
    return "rajdhani";
  if (t.includes("SHATABDI") || n.includes("SHATABDI") || n.includes("SHTBDI"))
    return "shatabdi";
  if (t.includes("DURONTO") || n.includes("DURONTO")) return "duronto";
  if (n.includes("TEJAS")) return "tejas";
  if (t.includes("SUPERFAST") || n.includes(" SF ") || n.endsWith(" SF EXP"))
    return "superfast";
  return "express";
}

export const trains: readonly CatalogTrain[] = TRAIN_INDEX.flatMap((entry) => {
  const dash = entry.indexOf("-");
  if (dash < 0) return [];
  const number = entry.slice(0, dash).trim();
  const rawName = entry.slice(dash + 1).trim();
  if (!number || !rawName) return [];
  return [
    {
      number,
      rawName,
      name: prettyTrainName(rawName),
      category: categoryFor(rawName),
    },
  ];
}).sort((a, b) => (a.number < b.number ? -1 : a.number > b.number ? 1 : 0));

const trainByNumberMap = new Map(trains.map((t) => [t.number, t]));

/**
 * Number-prefix matches first, then name hits — the Flighty ranking. The
 * query is tested against the number, erail's raw name, and the expanded
 * display name (so "rajdhani" reaches "NDLS TEJAS RAJ" → "NDLS Tejas
 * Rajdhani").
 */
export function searchTrains(query: string, limit = 30): CatalogTrain[] {
  const q = query.trim().toUpperCase();
  if (!q) return [];
  const prefix: CatalogTrain[] = [];
  const contains: CatalogTrain[] = [];
  for (const t of trains) {
    const name = t.name.toUpperCase();
    const raw = t.rawName;
    if (t.number.startsWith(q) || raw.startsWith(q) || name.startsWith(q)) {
      prefix.push(t);
    } else if (t.number.includes(q) || raw.includes(q) || name.includes(q)) {
      contains.push(t);
    }
    if (prefix.length >= limit) break;
  }
  return prefix.concat(contains).slice(0, limit);
}

export function searchStations(query: string, limit = 12): CatalogStation[] {
  const q = query.trim().toUpperCase();
  if (!q) return [];
  const codeHits: CatalogStation[] = [];
  const nameHits: CatalogStation[] = [];
  for (const s of stations) {
    const n = s.n.toUpperCase();
    if (s.c.startsWith(q)) {
      codeHits.push(s);
    } else if (n.startsWith(q) || n.includes(" " + q)) {
      nameHits.push(s);
    }
    if (codeHits.length >= limit) break;
  }
  return codeHits.concat(nameHits).slice(0, limit);
}

/** Exact lookup by train number ("12951"). */
export function trainByNumber(number: string): CatalogTrain | undefined {
  return trainByNumberMap.get(number.trim());
}

/** Exact lookup by station code ("NDLS"), case-insensitive. */
export function stationByCode(code: string): CatalogStation | undefined {
  return stationByCodeMap.get(code.trim().toUpperCase());
}
