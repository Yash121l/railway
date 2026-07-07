import { ImageResponse } from "next/og";

export const alt = "Railly — Get the truth when you take the train";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OgImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 72,
          background: "linear-gradient(180deg, #120036 0%, #0d0021 55%, #05010d 100%)",
          color: "#ffffff",
          fontFamily: "system-ui, sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: 14,
              background: "#007bff",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 30,
            }}
          >
            🚆
          </div>
          <div style={{ fontSize: 40, fontWeight: 700, letterSpacing: -1 }}>
            Railly
          </div>
        </div>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 20,
          }}
        >
          <div
            style={{
              fontSize: 72,
              fontWeight: 700,
              letterSpacing: -2.4,
              lineHeight: 1.02,
              maxWidth: 900,
            }}
          >
            Get the truth when you take the train.
          </div>
          <div style={{ fontSize: 28, color: "#cfcfcf", maxWidth: 820 }}>
            Live tracking, delay predictions before the railway admits it, and
            platform alerts — for every journey.
          </div>
        </div>

        <div style={{ display: "flex", gap: 12 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              borderRadius: 999,
              background: "rgba(48, 209, 88, 0.18)",
              color: "#30d158",
              padding: "10px 22px",
              fontSize: 22,
              fontWeight: 600,
            }}
          >
            ON TIME
          </div>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              borderRadius: 999,
              background: "rgba(247, 190, 0, 0.18)",
              color: "#f7be00",
              padding: "10px 22px",
              fontSize: 22,
              fontWeight: 600,
            }}
          >
            DELAYED +20M · PREDICTED 5H EARLY
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
