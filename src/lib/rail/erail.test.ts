import { readFileSync } from "node:fs";
import { afterEach, describe, expect, it, vi } from "vitest";
import { route, trainInfo, trainsBetween } from "./erail";

const fixture = (name: string) =>
  readFileSync(new URL(`./__fixtures__/${name}`, import.meta.url), "utf8");

function serve(body: string) {
  vi.stubGlobal("fetch", vi.fn(async () => new Response(body)));
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("erail getTrains.aspx (TrainNo)", () => {
  it("parses the recorded 12951 lookup", async () => {
    serve(fixture("erail-train-12951.txt"));
    const t = await trainInfo("12951");
    expect(t).toMatchObject({
      number: "12951",
      name: "NDLS TEJAS RAJ",
      category: "rajdhani",
      originCode: "MMCT",
      originName: "Mumbai Central",
      destCode: "NDLS",
      destName: "New Delhi",
      fromCode: "MMCT",
      toCode: "NDLS",
      departure: "17:00",
      arrival: "08:32",
      travelTime: "15:32",
      days: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      trainId: 2633,
      typeName: "RAJDHANI",
      distanceKm: 1384,
      classes: ["1A", "2A", "3A"],
    });
  });

  it("throws notFound when the number is absent", async () => {
    serve(fixture("erail-train-12951.txt"));
    await expect(trainInfo("99999")).rejects.toMatchObject({ kind: "notFound" });
  });
});

describe("erail getTrains.aspx (between)", () => {
  it("skips the header row and parses every train row", async () => {
    serve(fixture("erail-between-NDLS-MMCT.txt"));
    const rows = await trainsBetween("NDLS", "MMCT");
    expect(rows.map((r) => r.number)).toEqual(["12952", "22656", "22654"]);
    for (const r of rows) {
      expect(r.departure).toMatch(/^\d{2}:\d{2}$/);
      expect(r.originCode).toMatch(/^[A-Z]{2,5}$/);
      expect(r.trainId).toBeGreaterThan(0);
    }
  });

  it("throws notFound on an empty body", async () => {
    serve("");
    await expect(trainsBetween("NDLS", "MMCT")).rejects.toMatchObject({ kind: "notFound" });
  });
});

describe("erail data.aspx TRAINROUTE", () => {
  it("parses the recorded 12951 route", async () => {
    serve(fixture("erail-route-2633.txt"));
    const stops = await route(2633);
    expect(stops.map((s) => s.code)).toEqual([
      "MMCT", "BVI", "ST", "BRC", "RTM", "NAD", "KOTA", "NDLS",
    ]);
    expect(stops[0]).toMatchObject({ name: "Mumbai Central", arrMin: 0, depMin: 0, platform: undefined });
    expect(stops[2]).toMatchObject({ code: "ST", arrMin: 163, depMin: 168, distanceKm: 263 });
    expect(stops.at(-1)).toMatchObject({ code: "NDLS", arrMin: 932, distanceKm: 1384 });
    for (const s of stops) {
      expect(s.lat).toBeGreaterThan(8);
      expect(s.lat).toBeLessThan(37);
      expect(s.lng).toBeGreaterThan(68);
      expect(s.lng).toBeLessThan(98);
    }
  });

  it("rejects a body with fewer than two stops", async () => {
    serve("");
    await expect(route(2633)).rejects.toMatchObject({ kind: "badResponse" });
  });
});
