export const animations = {
  flyOut: {
    duration: 0.5, // Réduit pour mobile
    timing: "ease-out",
    keyframes: [
      { transform: "translateY(0)" },
      { transform: "translateY(-10px)" },
      { transform: "translateY(0)" }
    ]
  },
  collision: {
    duration: 0.4,
    timing: "linear",
    keyframes: [
      { transform: "translateY(0)" },
      { transform: "translateY(-3px)" },
      { transform: "translateY(3px)" },
      { transform: "translateY(0)" }
    ]
  },
  flyOutMobile: { // Animation spécifique pour mobile
    duration: 0.3,
    timing: "ease-in-out",
    keyframes: [
      { transform: "translateY(0)" },
      { transform: "translateY(-8px)" },
      { transform: "translateY(0)" }
    ]
  }
};
