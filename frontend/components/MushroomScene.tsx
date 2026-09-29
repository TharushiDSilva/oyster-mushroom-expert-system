export default function MushroomScene() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
      {/* soft ambient blob */}
      <div className="absolute -right-8 top-4 h-40 w-40 rounded-full bg-[#514a38]/50 blur-md sm:h-56 sm:w-56" />

      {/* top-left: morel-style textured cap */}
      <svg
        viewBox="0 0 160 200"
        className="absolute -left-10 top-2 h-28 w-24 opacity-70 sm:h-40 sm:w-32 sm:opacity-90"
      >
        <path
          d="M20 90 C10 40 45 5 80 5 C115 5 145 40 135 90 C130 115 105 120 80 120 C55 120 25 115 20 90Z"
          fill="#c9b35a"
        />
        <g stroke="#a68f3f" strokeWidth="3" strokeLinecap="round">
          <path d="M35 40 L55 75" />
          <path d="M55 30 L75 70" />
          <path d="M75 25 L90 68" />
          <path d="M95 30 L105 72" />
          <path d="M110 45 L115 78" />
        </g>
        <rect x="62" y="115" width="26" height="70" rx="10" fill="#e9ddbf" />
      </svg>

      {/* top-right: chanterelle / trumpet mushroom */}
      <svg
        viewBox="0 0 200 220"
        className="absolute -right-10 -top-8 h-40 w-36 sm:h-56 sm:w-48"
      >
        <path
          d="M100 10 C150 30 175 80 165 130 C160 150 140 160 100 210 C60 160 40 150 35 130 C25 80 50 30 100 10Z"
          fill="#f0923d"
        />
        <g stroke="#c96f28" strokeWidth="3" strokeLinecap="round">
          <path d="M100 45 L100 150" />
          <path d="M80 55 L70 140" />
          <path d="M120 55 L130 140" />
          <path d="M65 70 L50 130" />
          <path d="M135 70 L150 130" />
        </g>
      </svg>

      {/* bottom-left: spotted toadstool pair */}
      <svg
        viewBox="0 0 220 180"
        className="absolute -bottom-10 -left-8 h-36 w-40 sm:h-48 sm:w-56"
      >
        <rect x="45" y="90" width="18" height="70" rx="8" fill="#f4ecdc" />
        <path
          d="M10 90 C10 55 40 35 65 35 C90 35 115 55 115 90 C115 100 90 105 65 105 C40 105 10 100 10 90Z"
          fill="#c1453a"
        />
        <circle cx="35" cy="65" r="6" fill="#f4ecdc" />
        <circle cx="65" cy="55" r="5" fill="#f4ecdc" />
        <circle cx="90" cy="68" r="6" fill="#f4ecdc" />
        <circle cx="55" cy="80" r="4" fill="#f4ecdc" />

        <rect x="145" y="105" width="14" height="55" rx="7" fill="#f4ecdc" />
        <path
          d="M118 105 C118 78 140 62 158 62 C176 62 196 78 196 105 C196 113 176 117 158 117 C140 117 118 113 118 105Z"
          fill="#c1453a"
        />
        <circle cx="138" cy="88" r="5" fill="#f4ecdc" />
        <circle cx="160" cy="80" r="4" fill="#f4ecdc" />
        <circle cx="178" cy="90" r="5" fill="#f4ecdc" />
      </svg>

      {/* bottom-right: cream mushroom cluster */}
      <svg
        viewBox="0 0 220 180"
        className="absolute -bottom-8 -right-10 h-40 w-44 sm:h-56 sm:w-64"
      >
        <rect x="150" y="90" width="20" height="70" rx="10" fill="#e9ddbf" />
        <ellipse cx="160" cy="85" rx="55" ry="35" fill="#d9cba3" />
        <rect x="90" y="110" width="16" height="55" rx="8" fill="#e9ddbf" />
        <ellipse cx="98" cy="105" rx="42" ry="28" fill="#c7b78d" />
      </svg>

      {/* growth-ring doodle */}
      <svg
        viewBox="0 0 120 120"
        className="absolute bottom-3 left-8 h-14 w-14 opacity-40 sm:h-20 sm:w-20"
      >
        <g fill="none" stroke="#b6ab93" strokeWidth="2">
          <circle cx="60" cy="60" r="12" />
          <circle cx="60" cy="60" r="24" />
          <circle cx="60" cy="60" r="36" />
          <circle cx="60" cy="60" r="48" />
        </g>
      </svg>
    </div>
  );
}
