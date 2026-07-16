import { randomUUID } from "node:crypto";

/**
 * Server-only client for confirmtkt.com's free, live PNR status — the same
 * public web API the confirmtkt.com PNR page calls (static web apikey, no
 * account, no paid plan). Ported from ios/Railly/ConfirmTktAPI.swift.
 *
 * Captured by sniffing the site's own XHR (Jul 2026):
 *   POST https://cttrainsapi.confirmtkt.com/api/v2/ctpro/mweb/{pnr}
 *        ?querysource=ct-mweb&locale=en&getHighChanceText=true&livePnr=false
 *   headers: apikey: ct-mweb!2$ · clientid: ct-mweb · deviceid: <uuid>
 *   body: {"proPlanName":"CP7","emailId":"","tempToken":""}
 * Invalid/flushed PNRs come back inside `pnrResponse` with `error` + `errorCode`.
 */

export class PnrError extends Error {
  readonly kind: "invalid" | "network";
  constructor(kind: "invalid" | "network", message: string) {
    super(message);
    this.kind = kind;
    this.name = "PnrError";
  }
}

export interface RealPassenger {
  booking: string;
  current: string;
  coach?: string;
  berth?: number;
  bookingCoach?: string;
  bookingBerth?: number;
  /** ConfirmTkt's confirmation-chance text ("67% Chance") */
  prediction?: string;
}

export interface RealTicket {
  trainNumber: string;
  /** "yyyy-MM-dd" */
  doj?: string;
  boardingCode?: string;
  resUptoCode?: string;
  fromCode?: string;
  toCode?: string;
  journeyClass: string;
  quota?: string;
  chartPrepared: boolean;
  /** whole-ticket fare in rupees, as charged */
  fare?: number;
  /** "L SLR UR S7 S6 … B1 A1" — the live rake formation */
  coachPosition?: string;
  passengers: RealPassenger[];
}

/** Stable per-process device id, as the web client sends. */
const DEVICE_ID = randomUUID();

export async function pnrStatus(pnr: string): Promise<RealTicket> {
  const url =
    `https://cttrainsapi.confirmtkt.com/api/v2/ctpro/mweb/${encodeURIComponent(pnr)}` +
    `?querysource=ct-mweb&locale=en&getHighChanceText=true&livePnr=false`;

  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      cache: "no-store",
      signal: AbortSignal.timeout(20_000),
      headers: {
        apikey: "ct-mweb!2$",
        clientid: "ct-mweb",
        deviceid: DEVICE_ID,
        "content-type": "application/json",
        referer: "https://www.confirmtkt.com/",
      },
      body: JSON.stringify({ proPlanName: "CP7", emailId: "", tempToken: "" }),
    });
  } catch {
    throw new PnrError("network", "Couldn't reach the PNR service.");
  }

  // fetch doesn't throw on HTTP errors — don't parse a 4xx/5xx body as a booking
  if (!res.ok) throw new PnrError("network", "Couldn't reach the PNR service.");

  // Tolerant parsing: the schema is theirs to change, so pull fields
  // dynamically instead of trusting a rigid shape.
  let root: unknown;
  try {
    root = await res.json();
  } catch {
    throw new PnrError("network", "Couldn't read the PNR service.");
  }

  const resp = pluck(pluck(root, "data"), "pnrResponse");
  if (!isRecord(resp)) throw new PnrError("network", "Couldn't read the PNR service.");

  const err = str(resp.error);
  if (err) throw new PnrError("invalid", err);

  const trainNumber = str(resp.trainNo);
  if (!trainNumber) throw new PnrError("invalid", "No booking found for this PNR");

  const paxRaw = Array.isArray(resp.passengerStatus) ? resp.passengerStatus : [];
  const passengers: RealPassenger[] = paxRaw.filter(isRecord).map((p) => ({
    booking: str(p.bookingStatus) ?? "",
    current: str(p.currentStatus) ?? "",
    coach: firstNonEmpty(str(p.currentCoachId), str(p.coach)),
    berth: posInt(p.currentBerthNo) ?? posInt(p.berth),
    bookingCoach: str(p.bookingCoachId),
    bookingBerth: posInt(p.bookingBerthNo),
    prediction: str(p.prediction),
  }));
  // a real booking always carries passengers; an empty list means the schema
  // moved under us — fail honestly rather than render "NOT CNF"
  if (passengers.length === 0) {
    throw new PnrError("network", "PNR response had no passengers.");
  }

  return {
    trainNumber,
    doj: isoFromDMY(str(resp.doj)),
    boardingCode: str(resp.boardingPoint),
    resUptoCode: str(resp.reservationUpto),
    fromCode: str(resp.from),
    toCode: str(resp.to),
    journeyClass: str(resp.class) ?? "SL",
    quota: str(resp.quota),
    chartPrepared: resp.chartPrepared === true,
    fare: int(resp.ticketFare) ?? int(resp.bookingFare),
    coachPosition: str(resp.coachPosition),
    passengers,
  };
}

// MARK: dynamic-JSON helpers

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function pluck(v: unknown, key: string): unknown {
  return isRecord(v) ? v[key] : undefined;
}

function str(v: unknown): string | undefined {
  if (typeof v === "string") {
    const t = v.trim();
    return t === "" ? undefined : t;
  }
  if (typeof v === "number" && Number.isFinite(v)) return String(v);
  return undefined;
}

function int(v: unknown): number | undefined {
  if (typeof v === "number" && Number.isFinite(v)) return Math.trunc(v);
  if (typeof v === "string") {
    const n = Number(v.trim());
    return Number.isFinite(n) ? Math.trunc(n) : undefined;
  }
  return undefined;
}

/** Berth/seat numbers: the feed uses 0 for "not assigned yet". */
function posInt(v: unknown): number | undefined {
  const n = int(v);
  return n !== undefined && n > 0 ? n : undefined;
}

function firstNonEmpty(...vals: (string | undefined)[]): string | undefined {
  return vals.find((v) => v !== undefined && v !== "" && v !== "-");
}

/** "13-02-2024" → "2024-02-13". Strictly numeric; malformed dates fall to undefined. */
function isoFromDMY(s: string | undefined): string | undefined {
  const parts = (s ?? "").split("-");
  if (parts.length !== 3) return undefined;
  const d = Number(parts[0]);
  const m = Number(parts[1]);
  const y = Number(parts[2]);
  if (!Number.isInteger(d) || d < 1 || d > 31) return undefined;
  if (!Number.isInteger(m) || m < 1 || m > 12) return undefined;
  if (!Number.isInteger(y) || y < 2000 || y > 2200) return undefined;
  return `${String(y).padStart(4, "0")}-${String(m).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
}
