import Image from "next/image";

/**
 * The hero device: a frame around a real screenshot of the running app —
 * flighty.com's imagery is always the actual product, never an illustration.
 * The screenshot is the LCP element, so it preloads at hero priority.
 */
export function PhoneMock() {
  return (
    <div className="relative mx-auto w-[300px] rounded-[48px] bg-[#0c0d10] p-[9px] shadow-deep ring-1 ring-black/60 md:w-[336px] md:rounded-[54px] md:p-[10px]">
      <div className="relative overflow-hidden rounded-[39px] bg-black md:rounded-[44px]">
        <Image
          src="/screens/my-trips.png"
          alt="Railly's My Trips screen: a live network map of India above a list of tracked journeys"
          width={430}
          height={932}
          preload
          sizes="(min-width: 768px) 336px, 300px"
          className="block w-full"
        />
        {/* dynamic island */}
        <div className="absolute left-1/2 top-2.5 h-[24px] w-[86px] -translate-x-1/2 rounded-full bg-black" />
      </div>
    </div>
  );
}
