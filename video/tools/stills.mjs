import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import path from "node:path";

const [id = "Launch", framesArg = "", outDir = "out/stills"] = process.argv.slice(2);
const frames = framesArg.split(",").filter(Boolean).map(Number);
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts") });
const browserExecutable = process.env.REMOTION_BROWSER ?? null;
const composition = await selectComposition({ serveUrl, id, browserExecutable });
for (const frame of frames) {
  const output = `${outDir}/${id}-${String(frame).padStart(4, "0")}.jpg`;
  await renderStill({ composition, serveUrl, frame, output, imageFormat: "jpeg", jpegQuality: 80, browserExecutable });
  console.log(output);
}
