import React from "react";

export const Icon: React.FC<{ size: number; glow?: number }> = ({ size, glow = 0 }) => (
  <svg width={size} height={size} viewBox="0 0 64 64" style={{ overflow: "visible", display: "block" }}>
    <defs>
      <linearGradient id="icon-bg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#1c1f40" />
        <stop offset="1" stopColor="#05010d" />
      </linearGradient>
      <radialGradient id="icon-lamp">
        <stop offset="0" stopColor="#fff6cc" stopOpacity={0.95} />
        <stop offset="0.35" stopColor="#f7be00" stopOpacity={0.55} />
        <stop offset="1" stopColor="#f7be00" stopOpacity={0} />
      </radialGradient>
    </defs>
    <rect width="64" height="64" rx="14.5" fill="url(#icon-bg)" />
    <rect width="64" height="64" rx="14.5" fill="none" stroke="rgba(255,255,255,0.12)" strokeWidth="0.5" />
    <path
      d="M32 10c7.5 0 13 1.6 13 9.5V38c0 4.5-2.6 7.5-6.5 8.6l4.9 6.4a1.6 1.6 0 0 1-2.5 2l-6-7.5h-5.8l-6 7.5a1.6 1.6 0 0 1-2.5-2l4.9-6.4C21.6 45.5 19 42.5 19 38V19.5c0-7.9 5.5-9.5 13-9.5Z"
      fill="#ffffff"
    />
    <rect x="23" y="17" width="18" height="11" rx="3.4" fill="#0d0021" />
    {glow > 0 && (
      <>
        <circle cx="25.6" cy="37.4" r={2.6 + 9 * glow} fill="url(#icon-lamp)" opacity={glow} />
        <circle cx="38.4" cy="37.4" r={2.6 + 9 * glow} fill="url(#icon-lamp)" opacity={glow} />
      </>
    )}
    <circle cx="25.6" cy="37.4" r="2.6" fill="#f7be00" />
    <circle cx="38.4" cy="37.4" r="2.6" fill="#f7be00" />
  </svg>
);
