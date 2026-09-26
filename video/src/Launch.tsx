import React from "react";
import { AbsoluteFill, Audio, Sequence, getStaticFiles, staticFile } from "remotion";
import { Grain, Vignette } from "./lib/ui";
import { makeAppClip } from "./scenes/AppClip";
import { End } from "./scenes/End";
import { Headlights } from "./scenes/Headlights";
import { Honest } from "./scenes/Honest";
import { Hook } from "./scenes/Hook";
import { Live } from "./scenes/Live";
import { Logo } from "./scenes/Logo";
import { Network } from "./scenes/Network";
import { Slam } from "./scenes/Slam";
import { C, scene } from "./theme";

const blue = "#8fc0ff";

const Fly = makeAppClip({
  id: "fly",
  chapter: { text: "ON BOARD" },
  lines: [{ text: "Tap your train. Follow it.", accent: { Follow: blue, "it.": blue }, sub: "The globe flies to its real track. Position estimated from the timetable.", at: 10 }],
  push: [[100, 1.3, 0.18]],
});

const Detail = makeAppClip({
  id: "detail",
  chapter: { text: "AT THE STATION" },
  lines: [
    { text: "Platform. Delay. And why.", accent: { "why.": "#ff6b5e" }, at: 10 },
    { text: "Know where your coach stops.", accent: { coach: blue }, sub: "Composition is indicative. Rakes can run reversed.", at: 150 },
  ],
  push: [[40, 1.12, 0.3], [150, 1.12, 0.62], [250, 1, 0.5]],
});

const Pnr = makeAppClip({
  id: "pnr",
  chapter: { text: "BEFORE YOU GO" },
  lines: [{ text: "Your PNR, decoded.", accent: { "decoded.": blue }, sub: "Every passenger's status, berth, and coach position.", at: 10 }],
  push: [[50, 1.18, 0.15], [150, 1.14, 0.7]],
});

const Add = makeAppClip({
  id: "add",
  chapter: { text: "BEFORE YOU GO", continues: true },
  lines: [{ text: "Add your trip in seconds.", accent: { "seconds.": blue }, sub: "Search 4,022 trains by number, name, station, or PNR.", at: 6 }],
  push: [[20, 1.16, 0.12], [210, 1.2, 0.2]],
});

const Passport = makeAppClip({
  id: "passport",
  chapter: { text: "YOU'VE ARRIVED" },
  tone: "violet",
  lines: [{ text: "Every kilometre, in your Passport.", accent: { "Passport.": "#b9a8ff" }, sub: "Distance on real track, rail time, and the hours lost to delays.", at: 10 }],
  push: [[30, 1.15, 0.3]],
});

const SCENES: [string, React.FC][] = [
  ["hook", Hook],
  ["headlights", Headlights],
  ["logo", Logo],
  ["network", Network],
  ["pnr", Pnr],
  ["add", Add],
  ["detail", Detail],
  ["fly", Fly],
  ["live", Live],
  ["passport", Passport],
  ["slam", Slam],
  ["honest", Honest],
  ["end", End],
];

export const Launch: React.FC = () => {
  const hasScore = getStaticFiles().some((f) => f.name === "score.wav");
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      {SCENES.map(([id, Scene]) => {
        const { from, duration } = scene(id);
        return (
          <Sequence key={id} from={from} durationInFrames={duration} name={id}>
            <Scene />
          </Sequence>
        );
      })}
      <Vignette strength={0.45} />
      <Grain opacity={0.06} />
      {hasScore && <Audio src={staticFile("score.wav")} />}
    </AbsoluteFill>
  );
};
