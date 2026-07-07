import type { TrainCategory } from "./types";

export const CATEGORY_LABEL: Record<TrainCategory, string> = {
  rajdhani: "Rajdhani",
  "vande-bharat": "Vande Bharat",
  shatabdi: "Shatabdi",
  duronto: "Duronto",
  tejas: "Tejas",
  superfast: "Superfast",
  express: "Express",
};

/** City shown under the station code, departure-board style */
const CITY_BY_CODE: Record<string, string> = {
  MMCT: "Mumbai",
  BVI: "Mumbai",
  NDLS: "New Delhi",
  HWH: "Kolkata",
  SDAH: "Kolkata",
  SHM: "Kolkata",
  MAS: "Chennai",
  SBC: "Bengaluru",
  GNC: "Gandhinagar",
  DDU: "Deen Dayal Upadhyaya",
  VGLJ: "Jhansi",
  PRYJ: "Prayagraj",
  BSB: "Varanasi",
};

export function cityFor(code: string, stationName: string): string {
  if (CITY_BY_CODE[code]) return CITY_BY_CODE[code];
  return stationName
    .replace(/\s+(Junction|Jn|Central|Cantt|Capital|City)\.?$/i, "")
    .trim();
}
