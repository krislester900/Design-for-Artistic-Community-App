export function LoadingScreen() {
  return (
    <div className="loading-screen">
      <div className="loading-container">
        {/* Alien face SVG */}
        <div className="alien-wrapper">
          <svg
            viewBox="0 0 200 260"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            className="alien-svg"
          >
            {/* Head - large oval */}
            <ellipse cx="100" cy="110" rx="72" ry="90" className="alien-head" />

            {/* Left eye - big almond shape */}
            <ellipse cx="72" cy="100" rx="24" ry="30" className="alien-eye-bg" />
            <ellipse cx="72" cy="100" rx="24" ry="30" className="alien-eye-lid alien-left-lid" />
            <ellipse cx="72" cy="102" rx="14" ry="18" className="alien-pupil" />
            <circle cx="68" cy="96" r="5" className="alien-eye-shine" />

            {/* Right eye - big almond shape */}
            <ellipse cx="128" cy="100" rx="24" ry="30" className="alien-eye-bg" />
            <ellipse cx="128" cy="100" rx="24" ry="30" className="alien-eye-lid alien-right-lid" />
            <ellipse cx="128" cy="102" rx="14" ry="18" className="alien-pupil" />
            <circle cx="124" cy="96" r="5" className="alien-eye-shine" />

            {/* Nose - tiny lines */}
            <line x1="96" y1="130" x2="100" y2="138" className="alien-nose" />
            <line x1="104" y1="130" x2="100" y2="138" className="alien-nose" />

            {/* Mouth - thin curved line */}
            <path d="M82 155 Q100 165 118 155" className="alien-mouth" />

            {/* Subtle chin line */}
            <path d="M80 175 Q100 195 120 175" className="alien-chin" />

            {/* Antenna left */}
            <line x1="60" y1="25" x2="75" y2="45" className="alien-antenna" />
            <circle cx="57" cy="22" r="5" className="alien-antenna-tip" />

            {/* Antenna right */}
            <line x1="140" y1="25" x2="125" y2="45" className="alien-antenna" />
            <circle cx="143" cy="22" r="5" className="alien-antenna-tip" />
          </svg>
        </div>

        {/* Water puddle that forms under the alien */}
        <div className="puddle-container">
          <div className="puddle puddle-1" />
          <div className="puddle puddle-2" />
          <div className="puddle puddle-3" />
        </div>

        {/* Drip particles */}
        <div className="drip drip-1" />
        <div className="drip drip-2" />
        <div className="drip drip-3" />
        <div className="drip drip-4" />
        <div className="drip drip-5" />

        {/* Text */}
        <div className="loading-text">
          <span className="loading-label">ARTÉÏA</span>
        </div>
      </div>

      <style>{`
        /* ═══ KEYFRAMES ═══ */

        @keyframes alienEnter {
          0% {
            opacity: 0;
            transform: translateY(-30px) scale(0.8);
            filter: blur(8px);
          }
          60% {
            opacity: 1;
            transform: translateY(5px) scale(1.03);
            filter: blur(0);
          }
          100% {
            opacity: 1;
            transform: translateY(0) scale(1);
            filter: blur(0);
          }
        }

        @keyframes alienBlink {
          0%, 42%, 46%, 100% {
            transform: scaleY(1);
          }
          44% {
            transform: scaleY(0.05);
          }
        }

        @keyframes alienBlink2 {
          0%, 55%, 59%, 100% {
            transform: scaleY(1);
          }
          57% {
            transform: scaleY(0.05);
          }
        }

        @keyframes antennaWiggle {
          0%, 100% { transform: rotate(0deg); }
          25% { transform: rotate(3deg); }
          75% { transform: rotate(-3deg); }
        }

        @keyframes alienMelt {
          0% {
            transform: translateY(0) scaleX(1) scaleY(1);
            opacity: 1;
            filter: blur(0);
          }
          30% {
            transform: translateY(10px) scaleX(1.05) scaleY(0.95);
            opacity: 0.9;
          }
          60% {
            transform: translateY(40px) scaleX(1.2) scaleY(0.7);
            opacity: 0.6;
            filter: blur(2px);
          }
          100% {
            transform: translateY(80px) scaleX(1.8) scaleY(0.2);
            opacity: 0;
            filter: blur(8px);
          }
        }

        @keyframes puddleExpand {
          0% {
            transform: scale(0) scaleY(0.3);
            opacity: 0;
          }
          40% {
            transform: scale(0.6) scaleY(0.5);
            opacity: 0.8;
          }
          70% {
            transform: scale(1) scaleY(0.6);
            opacity: 0.5;
          }
          100% {
            transform: scale(1.3) scaleY(0.4);
            opacity: 0;
          }
        }

        @keyframes puddleRipple {
          0% {
            transform: scale(0.3);
            opacity: 0.6;
            border-width: 2px;
          }
          100% {
            transform: scale(2.5);
            opacity: 0;
            border-width: 0.5px;
          }
        }

        @keyframes dripFall {
          0% {
            transform: translateY(0) scaleY(1);
            opacity: 0;
          }
          10% {
            opacity: 1;
          }
          80% {
            opacity: 0.6;
          }
          100% {
            transform: translateY(120px) scaleY(1.5);
            opacity: 0;
          }
        }

        @keyframes dripSplash {
          0% {
            transform: scale(0);
            opacity: 0.8;
          }
          100% {
            transform: scale(3);
            opacity: 0;
          }
        }

        @keyframes labelFade {
          0%, 60% {
            opacity: 1;
            letter-spacing: 0.35em;
          }
          100% {
            opacity: 0;
            letter-spacing: 0.8em;
          }
        }

        @keyframes screenFade {
          0% { opacity: 1; }
          100% { opacity: 0; }
        }

        /* ═══ BASE ═══ */

        .loading-screen {
          position: fixed;
          inset: 0;
          z-index: 9999;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #0a0a0a;
          overflow: hidden;
          animation: screenFade 0.8s ease-in 3.8s forwards;
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

        /* ═══ ALIEN ═══ */

        .alien-wrapper {
          position: relative;
          z-index: 10;
          animation:
            alienEnter 0.8s cubic-bezier(0.22, 1, 0.36, 1) 0.2s both,
            alienMelt 1.2s cubic-bezier(0.4, 0, 0.2, 1) 3s forwards;
        }

        .alien-svg {
          width: 180px;
          height: 240px;
          filter: drop-shadow(0 0 30px rgba(255, 255, 255, 0.15));
        }

        .alien-head {
          fill: #ffffff;
          stroke: rgba(255, 255, 255, 0.3);
          stroke-width: 1;
        }

        .alien-eye-bg {
          fill: #0a0a0a;
          stroke: rgba(255, 255, 255, 0.15);
          stroke-width: 1;
        }

        .alien-eye-lid {
          fill: #ffffff;
          transform-origin: center;
          animation: alienBlink 4s ease-in-out 1.2s 1;
        }

        .alien-right-lid {
          animation: alienBlink2 4s ease-in-out 1.2s 1;
        }

        .alien-pupil {
          fill: #ffffff;
        }

        .alien-eye-shine {
          fill: #0a0a0a;
          opacity: 0.4;
        }

        .alien-nose {
          stroke: rgba(0, 0, 0, 0.3);
          stroke-width: 1.5;
          stroke-linecap: round;
        }

        .alien-mouth {
          stroke: rgba(0, 0, 0, 0.4);
          stroke-width: 1.5;
          fill: none;
          stroke-linecap: round;
        }

        .alien-chin {
          stroke: rgba(0, 0, 0, 0.1);
          stroke-width: 1;
          fill: none;
          stroke-linecap: round;
        }

        .alien-antenna {
          stroke: rgba(255, 255, 255, 0.6);
          stroke-width: 2;
          stroke-linecap: round;
          animation: antennaWiggle 2s ease-in-out infinite;
          transform-origin: bottom;
        }

        .alien-antenna-tip {
          fill: rgba(255, 255, 255, 0.8);
          animation: antennaWiggle 2s ease-in-out infinite;
        }

        /* ═══ PUDDLE ═══ */

        .puddle-container {
          position: absolute;
          bottom: 42%;
          left: 50%;
          transform: translateX(-50%);
          z-index: 5;
          opacity: 0;
          animation: puddleExpand 1.5s cubic-bezier(0.4, 0, 0.2, 1) 3.4s forwards;
        }

        .puddle {
          position: absolute;
          border-radius: 50%;
          background: radial-gradient(ellipse, rgba(255, 255, 255, 0.15) 0%, transparent 70%);
        }

        .puddle-1 {
          width: 160px;
          height: 40px;
          left: -80px;
          top: -20px;
        }

        .puddle-2 {
          width: 120px;
          height: 30px;
          left: -60px;
          top: -15px;
          animation-delay: 3.5s;
        }

        .puddle-3 {
          width: 80px;
          height: 20px;
          left: -40px;
          top: -10px;
          animation-delay: 3.6s;
        }

        /* ═══ RIPPLES ═══ */

        .puddle-container::before,
        .puddle-container::after {
          content: '';
          position: absolute;
          border: 1px solid rgba(255, 255, 255, 0.2);
          border-radius: 50%;
          left: 50%;
          top: 50%;
          transform: translate(-50%, -50%) scale(0.3);
          opacity: 0;
        }

        .puddle-container::before {
          width: 100px;
          height: 25px;
          animation: puddleRipple 1.8s ease-out 3.5s forwards;
        }

        .puddle-container::after {
          width: 60px;
          height: 15px;
          animation: puddleRipple 1.5s ease-out 3.7s forwards;
        }

        /* ═══ DRIPS ═══ */

        .drip {
          position: absolute;
          width: 4px;
          background: rgba(255, 255, 255, 0.5);
          border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
          opacity: 0;
          animation: dripFall 1s ease-in forwards;
          z-index: 8;
        }

        .drip::after {
          content: '';
          position: absolute;
          bottom: -2px;
          left: 50%;
          transform: translateX(-50%) scale(0);
          width: 8px;
          height: 4px;
          background: rgba(255, 255, 255, 0.3);
          border-radius: 50%;
          animation: dripSplash 0.4s ease-out forwards;
          animation-delay: inherit;
        }

        .drip-1 {
          left: calc(50% - 25px);
          top: 38%;
          height: 12px;
          animation-delay: 3.2s;
        }
        .drip-1::after { animation-delay: 4s; }

        .drip-2 {
          left: calc(50% + 15px);
          top: 40%;
          height: 10px;
          animation-delay: 3.4s;
        }
        .drip-2::after { animation-delay: 4.1s; }

        .drip-3 {
          left: calc(50% - 8px);
          top: 36%;
          height: 14px;
          animation-delay: 3.3s;
        }
        .drip-3::after { animation-delay: 3.95s; }

        .drip-4 {
          left: calc(50% + 30px);
          top: 42%;
          height: 8px;
          animation-delay: 3.5s;
        }
        .drip-4::after { animation-delay: 4.2s; }

        .drip-5 {
          left: calc(50% - 35px);
          top: 39%;
          height: 11px;
          animation-delay: 3.35s;
        }
        .drip-5::after { animation-delay: 4.05s; }

        /* ═══ TEXT ═══ */

        .loading-text {
          position: absolute;
          bottom: 15%;
          left: 50%;
          transform: translateX(-50%);
          z-index: 10;
          animation: labelFade 4.5s ease-in-out forwards;
        }

        .loading-label {
          font-family: 'Alien Block', cursive;
          font-size: 22px;
          font-weight: 300;
          letter-spacing: 0.35em;
          color: rgba(255, 255, 255, 0.7);
          text-shadow: 0 0 20px rgba(255, 255, 255, 0.1);
        }
      `}</style>
    </div>
  );
}