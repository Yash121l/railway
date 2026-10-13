import { readFileSync } from "node:fs";
import { afterEach, describe, expect, it, vi } from "vitest";
import { PnrError, pnrStatus } from "./confirmtkt";

const fixture = (name: string) =>
  readFileSync(new URL(`./__fixtures__/${name}`, import.meta.url), "utf8");

function serve(body: string, status = 200) {
  vi.stubGlobal("fetch", vi.fn(async () => new Response(body, { status })));
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("confirmtkt PNR", () => {
  it("surfaces the recorded flushed-PNR error as invalid", async () => {
    serve(fixture("confirmtkt-pnr-flushed.json"));
    await expect(pnrStatus("1234567890")).rejects.toMatchObject({
      kind: "invalid",
      message: "Flushed PNR /PNR not yet generated",
    });
  });

  it("parses a booked PNR", async () => {
    serve(fixture("confirmtkt-pnr-booked.synthetic.json"));
    const t = await pnrStatus("1234567890");
    expect(t).toEqual({
      trainNumber: "12951",
      doj: "2026-10-13",
      boardingCode: "BVI",
      resUptoCode: "NDLS",
      fromCode: "MMCT",
      toCode: "NDLS",
      journeyClass: "3A",
      quota: "GN",
      chartPrepared: true,
      fare: 4805,
      coachPosition: "L SLR B1 B2 B3 B4 PC A1 H1 SLR",
      passengers: [
        {
          booking: "WL 12",
          current: "CNF",
          coach: "B3",
          berth: 45,
          bookingCoach: undefined,
          bookingBerth: undefined,
          prediction: "Confirmed",
        },
        {
          booking: "WL 13",
          current: "RAC 2",
          coach: "B4",
          berth: 7,
          bookingCoach: undefined,
          bookingBerth: undefined,
          prediction: "67% Chance",
        },
      ],
    });
  });

  it("treats a missing pnrResponse as a network error", async () => {
    serve(JSON.stringify({ data: {} }));
    await expect(pnrStatus("1234567890")).rejects.toMatchObject({ kind: "network" });
  });

  it("does not parse an HTTP error body", async () => {
    serve(fixture("confirmtkt-pnr-booked.synthetic.json"), 503);
    await expect(pnrStatus("1234567890")).rejects.toBeInstanceOf(PnrError);
  });
});
