import { appendFile, mkdir } from "node:fs/promises";
import path from "node:path";

/**
 * The delay-history seed. Every live fetch appends one observation to
 * `.data/delay-history.jsonl` — the raw material for the future
 * delay-prediction moat. Fine for local/dev; see the serverless caveat below.
 *
 * Caveat: on ephemeral/serverless filesystems this write does not persist
 * across invocations and is lost on redeploy. In production this should target
 * a durable append log (object storage, a queue, or a managed database);
 * the local jsonl is a stand-in that starts collecting the signal today.
 */

const DATA_DIR = path.join(process.cwd(), ".data");
const HISTORY_FILE = path.join(DATA_DIR, "delay-history.jsonl");

export interface DelayObservation {
  trainNo: string;
  /** "yyyy-MM-dd" run date (IST) */
  date: string;
  /** station code the observation is anchored to */
  station: string;
  delayMin: number;
  /** ISO timestamp the observation was taken */
  at: string;
}

/** Best-effort append; telemetry must never fail the request. */
export async function recordDelay(obs: DelayObservation): Promise<void> {
  try {
    await mkdir(DATA_DIR, { recursive: true });
    await appendFile(HISTORY_FILE, `${JSON.stringify(obs)}\n`, "utf8");
  } catch {
    // swallow: seeding the history log is opportunistic
  }
}
