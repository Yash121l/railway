import Image from "next/image";
import { SCREEN_HEIGHT, SCREEN_WIDTH, SCREENS } from "./screens";

/**
 * The Dynamic Island, drawn over a screenshot. Simulator captures leave it
 * out, so the frame adds it. Sized in container units off the screen width
 * (126 x 37 pt, 11 pt down, on a 440 pt wide display), so it stays in
 * proportion in every frame size. The parent needs `@container`.
 */
export function DynamicIsland() {
  return (
    <div
      aria-hidden
      className="absolute left-1/2 top-[2.5cqw] h-[8.4cqw] w-[28.6cqw] -translate-x-1/2 rounded-full bg-black"
    />
  );
}

/**
 * The hero device: a frame around a real screenshot of the running app.
 * flighty.com's imagery is always the actual product, never an illustration.
 * The screenshot is the LCP element, so it preloads at hero priority.
 */
export function PhoneMock() {
  return (
    <div className="relative mx-auto w-[300px] rounded-[48px] bg-[#0c0d10] p-[9px] shadow-deep ring-1 ring-black/60 md:w-[336px] md:rounded-[54px] md:p-[10px]">
      <div className="@container relative overflow-hidden rounded-[39px] bg-black md:rounded-[44px]">
        <Image
          src={SCREENS.home}
          alt="Railly's home screen: a satellite globe of India with each trip drawn on its real track, and the My Trips sheet floating over it"
          width={SCREEN_WIDTH}
          height={SCREEN_HEIGHT}
          preload
          sizes="(min-width: 768px) 316px, 282px"
          className="block w-full"
        />
        <DynamicIsland />
      </div>
    </div>
  );
}
