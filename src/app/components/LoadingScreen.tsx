export function LoadingScreen() {
  return (
    <div className="loading-screen">
      <div className="loading-container">
        {/* Désert minimaliste - sol */}
        <div className="desert-ground">
          <div className="dune dune-1" />
          <div className="dune dune-2" />
          <div className="dune dune-3" />
        </div>

        {/* Soleil */}
        <div className="sun" />

        {/* Nuages */}
        <div className="cloud cloud-1" />
        <div className="cloud cloud-2" />
        <div className="cloud cloud-3" />

        {/* Lama qui court */}
        <div className="llama-runner">
          <svg
            viewBox="0 0 200 160"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            className="llama-svg"
          >
            {/* Corps */}
            <ellipse cx="100" cy="90" rx="55" ry="28" className="llama-body" />
            {/* Cou */}
            <path d="M130 75 Q150 50 155 35 L165 38 Q160 55 140 80Z" className="llama-neck" />
            {/* Tête */}
            <ellipse cx="160" cy="30" rx="18" ry="14" className="llama-head" />
            {/* Oreille */}
            <path d="M168 18 Q172 8 176 16 Q174 20 170 22Z" className="llama-ear" />
            <path d="M162 16 Q164 5 168 14 Q167 18 164 20Z" className="llama-ear" />
            {/* Œil */}
            <circle cx="166" cy="28" r="3" className="llama-eye" />
            {/* Museau */}
            <ellipse cx="177" cy="32" rx="5" ry="4" className="llama-snout" />
            {/* Bouche */}
            <path d="M175 35 Q178 38 181 35" className="llama-mouth" />
            {/* Pattes */}
            <line x1="70" y1="112" x2="65" y2="148" className="llama-leg leg-1" />
            <line x1="95" y1="114" x2="90" y2="148" className="llama-leg leg-2" />
            <line x1="113" y1="114" x2="110" y2="148" className="llama-leg leg-3" />
            <line x1="130" y1="110" x2="128" y2="148" className="llama-leg leg-4" />
            {/* Queue */}
            <path d="M48 85 Q35 78 32 88 Q38 92 45 88Z" className="llama-tail" />
            {/* Laine texture */}
            <circle cx="85" cy="85" r="8" className="llama-wool" />
            <circle cx="100" cy="80" r="9" className="llama-wool" />
            <circle cx="115" cy="83" r="7" className="llama-wool" />
          </svg>
        </div>

        {/* Particules de sable */}
        <div className="sand-particle p1" />
        <div className="sand-particle p2" />
        <div className="sand-particle p3" />
        <div className="sand-particle p4" />
        <div className="sand-particle p5" />

        {/* Texte de chargement */}
        <div className="loading-text">
          <span className="loading-label">CHARGEMENT</span>
          <div className="loading-dots">
            <span className="dot" />
            <span className="dot" />
            <span className="dot" />
          </div>
        </div>

        {/* Ligne de progression */}
        <div className="progress-track">
          <div className="progress-bar" />
        </div>
      </div>

      <style>{`
        @keyframes llamaRun {
          0% { transform: translateX(-120px) scaleX(1); }
          50% { transform: translateX(calc(50vw - 100px)) scaleX(1); }
          100% { transform: translateX(calc(100vw + 120px)) scaleX(1); }
        }

        @keyframes llamaBob {
          0%, 100% { transform: translateY(0) rotate(0deg); }
          25% { transform: translateY(-4px) rotate(1deg); }
          75% { transform: translateY(-2px) rotate(-1deg); }
        }

        @keyframes legRun1 {
          0%, 100% { transform: rotate(0deg); }
          25% { transform: rotate(20deg); }
          50% { transform: rotate(0deg); }
          75% { transform: rotate(-20deg); }
        }

        @keyframes legRun2 {
          0%, 100% { transform: rotate(0deg); }
          25% { transform: rotate(-20deg); }
          50% { transform: rotate(0deg); }
          75% { transform: rotate(20deg); }
        }

        @keyframes tailWag {
          0%, 100% { transform: rotate(-5deg); }
          50% { transform: rotate(15deg); }
        }

        @keyframes earTwitch {
          0%, 100% { transform: rotate(0deg); }
          30% { transform: rotate(8deg); }
          60% { transform: rotate(-5deg); }
        }

        @keyframes sunGlow {
          0%, 100% { opacity: 0.6; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.08); }
        }

        @keyframes cloudFloat {
          0% { transform: translateX(-200px); opacity: 0; }
          10% { opacity: 0.8; }
          90% { opacity: 0.8; }
          100% { transform: translateX(calc(100vw + 200px)); opacity: 0; }
        }

        @keyframes duneShift {
          0% { transform: translateX(0); }
          100% { transform: translateX(-50%); }
        }

        @keyframes sandFloat {
          0%, 100% { transform: translateY(0) translateX(0); opacity: 0; }
          20% { opacity: 0.6; }
          80% { opacity: 0.4; }
          100% { transform: translateY(-80px) translateX(30px); opacity: 0; }
        }

        @keyframes progressFill {
          0% { width: 0%; }
          70% { width: 72%; }
          85% { width: 85%; }
          100% { width: 100%; }
        }

        @keyframes dotPulse {
          0%, 100% { opacity: 0.3; transform: scale(0.8); }
          50% { opacity: 1; transform: scale(1.2); }
        }

        @keyframes fadeInUp {
          0% { opacity: 0; transform: translateY(20px); }
          100% { opacity: 1; transform: translateY(0); }
        }

        .loading-screen {
          position: fixed;
          inset: 0;
          z-index: 9999;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(
            180deg,
            #1a0a2e 0%,
            #2d1b4e 15%,
            #4a2c6e 30%,
            #c78a5a 55%,
            #e8b87a 65%,
            #f0d090 75%,
            #e8c878 85%,
            #d4a060 100%
          );
          overflow: hidden;
          animation: fadeInUp 0.4s ease-out;
        }

        .loading-container {
          position: relative;
          width: 100%;
          height: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
        }

        /* Désert - sol avec dunes */
        .desert-ground {
          position: absolute;
          bottom: 0;
          left: 0;
          right: 0;
          height: 45%;
          overflow: hidden;
        }

        .dune {
          position: absolute;
          bottom: 0;
          width: 200%;
          height: 100%;
          background: linear-gradient(
            180deg,
            transparent 0%,
            #d4a060 20%,
            #c8904a 50%,
            #b0783a 80%,
            #8a5a2a 100%
          );
          border-radius: 50% 50% 0 0 / 100% 100% 0 0;
        }

        .dune-1 {
          left: -25%;
          height: 85%;
          background: linear-gradient(
            180deg,
            transparent 0%,
            #e0b070 20%,
            #d09850 50%,
            #b8803a 80%,
            #9a6830 100%
          );
          animation: duneShift 8s linear infinite;
        }

        .dune-2 {
          left: 10%;
          height: 75%;
          background: linear-gradient(
            180deg,
            transparent 0%,
            #c8904a 20%,
            #b0783a 50%,
            #986828 80%,
            #785020 100%
          );
          animation: duneShift 12s linear infinite;
          animation-delay: -4s;
        }

        .dune-3 {
          left: 40%;
          height: 65%;
          background: linear-gradient(
            180deg,
            transparent 0%,
            #b8803a 20%,
            #a06828 50%,
            #885020 80%,
            #684018 100%
          );
          animation: duneShift 15s linear infinite;
          animation-delay: -8s;
        }

        /* Soleil */
        .sun {
          position: absolute;
          top: 8%;
          right: 18%;
          width: 120px;
          height: 120px;
          background: radial-gradient(circle, #ffd700 0%, #ff8c00 40%, transparent 70%);
          border-radius: 50%;
          animation: sunGlow 4s ease-in-out infinite;
          box-shadow: 0 0 80px rgba(255, 140, 0, 0.3),
                      0 0 160px rgba(255, 140, 0, 0.15);
        }

        /* Nuages minimalistes */
        .cloud {
          position: absolute;
          background: linear-gradient(
            90deg,
            rgba(255, 255, 255, 0.15) 0%,
            rgba(255, 255, 255, 0.25) 50%,
            rgba(255, 255, 255, 0.1) 100%
          );
          border-radius: 100px;
          height: 30px;
          animation: cloudFloat 20s linear infinite;
        }

        .cloud-1 {
          top: 12%;
          width: 180px;
          height: 25px;
          animation-duration: 25s;
        }

        .cloud-2 {
          top: 18%;
          width: 140px;
          height: 20px;
          animation-duration: 30s;
          animation-delay: -8s;
        }

        .cloud-3 {
          top: 6%;
          width: 100px;
          height: 15px;
          animation-duration: 22s;
          animation-delay: -15s;
        }

        /* Lama */
        .llama-runner {
          position: absolute;
          bottom: 38%;
          left: 50%;
          transform: translateX(-50%);
          animation: llamaRun 8s linear infinite, llamaBob 0.6s ease-in-out infinite;
          z-index: 10;
          filter: drop-shadow(0 8px 20px rgba(0, 0, 0, 0.3));
        }

        .llama-svg {
          width: 200px;
          height: 160px;
        }

        .llama-body {
          fill: #f5e6d0;
          stroke: #d4a060;
          stroke-width: 2;
        }

        .llama-neck {
          fill: #f0dcc0;
          stroke: #d4a060;
          stroke-width: 2;
        }

        .llama-head {
          fill: #f5e6d0;
          stroke: #d4a060;
          stroke-width: 2;
        }

        .llama-ear {
          fill: #f0dcc0;
          stroke: #d4a060;
          stroke-width: 1.5;
        }

        .llama-eye {
          fill: #2a1a0e;
        }

        .llama-snout {
          fill: #e8c8a0;
          stroke: #d4a060;
          stroke-width: 1.5;
        }

        .llama-mouth {
          stroke: #2a1a0e;
          stroke-width: 1.5;
          fill: none;
          stroke-linecap: round;
        }

        .llama-leg {
          stroke: #e8d0b0;
          stroke-width: 6;
          stroke-linecap: round;
        }

        .leg-1 {
          animation: legRun1 0.6s ease-in-out infinite;
          transform-origin: 70px 112px;
        }

        .leg-2 {
          animation: legRun2 0.6s ease-in-out infinite;
          transform-origin: 95px 114px;
        }

        .leg-3 {
          animation: legRun1 0.6s ease-in-out infinite;
          transform-origin: 113px 114px;
          animation-delay: -0.3s;
        }

        .leg-4 {
          animation: legRun2 0.6s ease-in-out infinite;
          transform-origin: 130px 110px;
          animation-delay: -0.3s;
        }

        .llama-tail {
          fill: #e8d0b0;
          stroke: #d4a060;
          stroke-width: 1.5;
          animation: tailWag 1.2s ease-in-out infinite;
          transform-origin: 48px 85px;
        }

        .llama-wool {
          fill: #faf0e0;
          opacity: 0.6;
        }

        /* Particules de sable */
        .sand-particle {
          position: absolute;
          width: 4px;
          height: 4px;
          background: #e0b070;
          border-radius: 50%;
          animation: sandFloat 3s ease-in-out infinite;
        }

        .p1 { bottom: 35%; left: 30%; animation-delay: 0s; }
        .p2 { bottom: 32%; left: 55%; animation-delay: 1s; }
        .p3 { bottom: 38%; left: 70%; animation-delay: 2s; }
        .p4 { bottom: 34%; left: 40%; animation-delay: 0.5s; }
        .p5 { bottom: 36%; left: 80%; animation-delay: 1.8s; }

        /* Texte de chargement */
        .loading-text {
          position: absolute;
          bottom: 12%;
          left: 50%;
          transform: translateX(-50%);
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 12px;
          animation: fadeInUp 0.8s ease-out 0.3s both;
        }

        .loading-label {
          font-family: 'Oswald', sans-serif;
          font-size: 20px;
          font-weight: 600;
          letter-spacing: 0.35em;
          color: rgba(255, 255, 255, 0.85);
          text-shadow: 0 2px 12px rgba(0, 0, 0, 0.3);
        }

        .loading-dots {
          display: flex;
          gap: 8px;
        }

        .dot {
          width: 8px;
          height: 8px;
          background: rgba(255, 255, 255, 0.7);
          border-radius: 50%;
          animation: dotPulse 1.4s ease-in-out infinite;
        }

        .dot:nth-child(2) { animation-delay: 0.2s; }
        .dot:nth-child(3) { animation-delay: 0.4s; }

        /* Barre de progression */
        .progress-track {
          position: absolute;
          bottom: 7%;
          left: 50%;
          transform: translateX(-50%);
          width: 240px;
          height: 3px;
          background: rgba(255, 255, 255, 0.12);
          border-radius: 10px;
          overflow: hidden;
          animation: fadeInUp 0.8s ease-out 0.5s both;
        }

        .progress-bar {
          height: 100%;
          background: linear-gradient(
            90deg,
            #ff6a1a,
            #d9ff38,
            #28d8ff
          );
          border-radius: 10px;
          animation: progressFill 2.6s ease-in-out forwards;
          box-shadow: 0 0 12px rgba(255, 106, 26, 0.4);
        }
      `}</style>
    </div>
  );
}