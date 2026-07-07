export type TrainCategory =
  | "rajdhani"
  | "vande-bharat"
  | "shatabdi"
  | "duronto"
  | "tejas"
  | "superfast"
  | "express";

export type Day = "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun";

export interface Stop {
  name: string;
  code: string;
  lat: number;
  lng: number;
  /** minutes after origin departure the train arrives here (0 at origin) */
  arrMin: number;
  /** minutes after origin departure the train departs (== arrMin at destination) */
  depMin: number;
  platform?: string;
}

export interface Train {
  number: string;
  name: string;
  category: TrainCategory;
  /** origin departure "HH:MM", IST */
  departureTime: string;
  days: Day[];
  distanceKm: number;
  stops: Stop[];
}

/** A journey the user holds a ticket for — always the train's full run in this demo. */
export interface Trip {
  id: string;
  trainNumber: string;
  /** YYYY-MM-DD (IST) of the run's origin departure */
  runDate: string;
  coach: string;
  seat: string;
  pnr: string;
}

export type RunPhase = "scheduled" | "boarding" | "enroute" | "arrived";

export type StatusTone = "go" | "sun" | "crit" | "signal" | "steel";

export interface StopTiming {
  arrSched: Date;
  arrEst: Date;
  depSched: Date;
  depEst: Date;
  /** arrival delay in minutes for this stop */
  delayMin: number;
  /** train has already departed this stop */
  passed: boolean;
  /** train is standing at this stop right now */
  current: boolean;
}

export type TrainEventKind =
  | "departed"
  | "stop"
  | "delay"
  | "recovery"
  | "platform"
  | "arrived"
  | "prediction";

export interface TrainEvent {
  time: Date;
  kind: TrainEventKind;
  text: string;
  detail?: string;
}

export interface LiveStatus {
  train: Train;
  runDate: string;
  phase: RunPhase;
  /** current delay in minutes (interpolated between stops) */
  delayMin: number;
  statusText: string;
  tone: StatusTone;
  position: { lat: number; lng: number };
  bearing: number;
  speedKmh: number;
  /** index of the last stop departed (or the stop being stood at) */
  prevStopIdx: number;
  nextStopIdx: number;
  atStation: boolean;
  stopTimings: StopTiming[];
  progressKm: number;
  totalKm: number;
  /** 0..1 along the route polyline */
  progress: number;
  departsAt: Date;
  arrivesSched: Date;
  arrivesEst: Date;
  events: TrainEvent[];
}
