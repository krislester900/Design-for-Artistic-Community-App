export function WelcomeBird() {
  return (
    <>
      <style>{`
        @keyframes welcomeFlyOut {
          0% { transform: translateY(0); opacity: 1; }
          50% { transform: translateY(-10px); opacity: 0.7; }
          100% { transform: translateY(0); opacity: 0; }
        }
      `}</style>
      <div
        className="absolute top-20 left-20 z-40 h-16 w-16 bg-gradient-to-br from-primary/20 to-accent/20 rounded-full"
        style={{
          animation: "welcomeFlyOut 0.5s ease-out forwards",
        }}
      />
    </>
  );
}