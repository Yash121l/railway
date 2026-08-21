"use client";

import { useState } from "react";
import { Loader2, Search, TriangleAlert } from "lucide-react";

/** Mirrors RealPassenger in src/lib/rail/confirmtkt.ts. */
interface Passenger {
  booking: string;
  current: string;
  coach?: string;
  berth?: number;
  bookingCoach?: string;
  bookingBerth?: number;
  prediction?: string;
}

/** Mirrors RealTicket in src/lib/rail/confirmtkt.ts. */
interface Ticket {
  trainNumber: string;
  doj?: string;
  boardingCode?: string;
  resUptoCode?: string;
  fromCode?: string;
  toCode?: string;
  journeyClass: string;
  quota?: string;
  chartPrepared: boolean;
  fare?: number;
  coachPosition?: string;
  passengers: Passenger[];
}

interface Result {
  source: string;
  asOf: string;
  ticket: Ticket;
}

type State =
  | { kind: "idle" }
  | { kind: "loading" }
  | { kind: "error"; message: string }
  | { kind: "done"; result: Result };

function groupPnr(digits: string) {
  return digits.length > 3 ? `${digits.slice(0, 3)} ${digits.slice(3)}` : digits;
}

/** CNF is settled, RAC is a shared berth, anything WL is still waiting. */
function statusTone(status: string) {
  const s = status.toUpperCase();
  if (s.startsWith("CNF") || s.startsWith("CAN")) return "text-ontime";
  if (s.startsWith("RAC")) return "text-sun";
  return "text-crit";
}

function fmtBerth(p: Passenger) {
  if (!p.coach && p.berth === undefined) return null;
  return [p.coach, p.berth].filter(Boolean).join(" · ");
}

export function PnrLookup() {
  const [digits, setDigits] = useState("");
  const [state, setState] = useState<State>({ kind: "idle" });

  const ready = digits.length === 10;

  async function check(e: React.FormEvent) {
    e.preventDefault();
    if (!ready) return;
    setState({ kind: "loading" });
    try {
      const res = await fetch(`/api/rail/pnr/${digits}`);
      const body = await res.json();
      if (!res.ok) {
        // The route already returns the service's own message; show it rather
        // than a generic failure, and never fall back to invented data.
        setState({
          kind: "error",
          message: body?.error ?? "Couldn't check that PNR.",
        });
        return;
      }
      setState({ kind: "done", result: body as Result });
    } catch {
      setState({
        kind: "error",
        message: "Couldn't reach Railly. Check your connection and try again.",
      });
    }
  }

  return (
    <div className="rounded-3xl bg-white p-6 shadow-float ring-1 ring-black/[0.05] md:p-8">
      <form onSubmit={check} className="flex flex-col gap-3 sm:flex-row">
        <label className="flex-1">
          <span className="sr-only">10-digit PNR number</span>
          <input
            value={groupPnr(digits)}
            onChange={(e) =>
              setDigits(e.target.value.replace(/\D/g, "").slice(0, 10))
            }
            inputMode="numeric"
            autoComplete="off"
            placeholder="Enter your 10-digit PNR"
            aria-describedby="pnr-help"
            className="tnum w-full rounded-2xl bg-linen px-5 py-4 text-[17px] font-semibold tracking-[1px] text-black outline-none ring-1 ring-black/[0.06] placeholder:font-normal placeholder:tracking-normal placeholder:text-steel focus:ring-2 focus:ring-signal"
          />
        </label>
        <button
          type="submit"
          disabled={!ready || state.kind === "loading"}
          className="inline-flex items-center justify-center gap-2 rounded-2xl bg-black px-6 py-4 text-[15px] font-semibold text-white transition-opacity disabled:opacity-40 sm:w-auto"
        >
          {state.kind === "loading" ? (
            <Loader2 size={17} className="animate-spin" />
          ) : (
            <Search size={17} />
          )}
          {state.kind === "loading" ? "Checking" : "Check PNR"}
        </button>
      </form>

      <p id="pnr-help" className="mt-3 text-[13px] leading-relaxed text-steel">
        Live status straight from the reservation system. Railly stores nothing:
        the lookup runs on request and the result is not saved.
      </p>

      {state.kind === "error" && (
        <div
          role="alert"
          className="mt-5 flex items-start gap-3 rounded-2xl bg-crit/[0.06] p-4 ring-1 ring-crit/20"
        >
          <TriangleAlert size={18} className="mt-0.5 shrink-0 text-crit" />
          <div>
            <div className="text-[15px] font-semibold text-black">
              {state.message}
            </div>
            <div className="mt-1 text-[13px] text-steel">
              This is the reservation service&apos;s own response, not a guess.
            </div>
          </div>
        </div>
      )}

      {state.kind === "done" && <TicketCard result={state.result} />}
    </div>
  );
}

function TicketCard({ result }: { result: Result }) {
  const t = result.ticket;
  const route = [t.boardingCode ?? t.fromCode, t.resUptoCode ?? t.toCode]
    .filter(Boolean)
    .join(" → ");

  return (
    <div className="mt-6 border-t border-black/[0.06] pt-6">
      <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
        <span className="tnum text-[22px] font-bold tracking-tight text-black">
          {t.trainNumber}
        </span>
        {route && (
          <span className="text-[15px] font-semibold text-carbon">{route}</span>
        )}
        <span
          className={`ml-auto rounded-full px-3 py-1 text-[11px] font-bold uppercase tracking-[1px] ${
            t.chartPrepared
              ? "bg-ontime/10 text-ontime"
              : "bg-black/[0.05] text-steel"
          }`}
        >
          {t.chartPrepared ? "Chart prepared" : "Chart not prepared"}
        </span>
      </div>

      <dl className="mt-4 grid grid-cols-2 gap-x-4 gap-y-3 sm:grid-cols-4">
        <Fact label="Date of journey" value={t.doj} />
        <Fact label="Class" value={t.journeyClass} />
        <Fact label="Quota" value={t.quota} />
        <Fact
          label="Fare"
          value={t.fare ? `₹${t.fare.toLocaleString("en-IN")}` : undefined}
        />
      </dl>

      <div className="mt-6 overflow-hidden rounded-2xl ring-1 ring-black/[0.06]">
        <table className="w-full text-left text-[14px]">
          <thead className="bg-linen">
            <tr className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
              <th className="px-4 py-3">Passenger</th>
              <th className="px-4 py-3">Booked as</th>
              <th className="px-4 py-3">Now</th>
              <th className="px-4 py-3">Coach · berth</th>
            </tr>
          </thead>
          <tbody>
            {t.passengers.map((p, i) => (
              <tr key={i} className="border-t border-black/[0.06]">
                <td className="px-4 py-3 font-semibold text-black">{i + 1}</td>
                <td className="px-4 py-3 text-carbon">{p.booking}</td>
                <td className={`px-4 py-3 font-semibold ${statusTone(p.current)}`}>
                  {p.current}
                  {p.prediction && (
                    <span className="ml-2 whitespace-nowrap text-[12px] font-medium text-steel">
                      {p.prediction} · ConfirmTkt
                    </span>
                  )}
                </td>
                <td className="tnum px-4 py-3 text-carbon">
                  {fmtBerth(p) ?? "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {t.coachPosition && (
        <div className="mt-5">
          <div className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
            Coach position, engine first
          </div>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {t.coachPosition.split(/\s+/).filter(Boolean).map((c, i) => {
              const mine = t.passengers.some((p) => p.coach && p.coach === c);
              return (
                <span
                  key={`${c}-${i}`}
                  className={`rounded-md px-2 py-1 text-[12px] font-bold ${
                    mine
                      ? "bg-black text-white"
                      : "bg-linen text-carbon ring-1 ring-black/[0.06]"
                  }`}
                >
                  {c}
                </span>
              );
            })}
          </div>
          <p className="mt-2 text-[12px] text-steel">
            From the chart. Rakes can still run reversed on the day.
          </p>
        </div>
      )}

      <p className="mt-6 text-[12px] text-steel">
        Live PNR status via ConfirmTkt · checked{" "}
        {new Date(result.asOf).toLocaleTimeString("en-IN", {
          hour: "2-digit",
          minute: "2-digit",
        })}{" "}
        IST. Railly is not affiliated with Indian Railways or IRCTC.
      </p>
    </div>
  );
}

function Fact({ label, value }: { label: string; value?: string }) {
  return (
    <div>
      <dt className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
        {label}
      </dt>
      <dd className="mt-1 text-[15px] font-semibold text-black">
        {value || "—"}
      </dd>
    </div>
  );
}
