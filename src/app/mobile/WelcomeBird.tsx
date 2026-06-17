import React from "react";
import { animations } from "../animations";

export function WelcomeBird() {
  return (
    <div
      className="absolute top-20 left-20 z-40 h-16 w-16 bg-gradient-to-br from-primary/20 to-accent/20 rounded-full"
      style={{
        animation: animations.flyOut,
        animationDuration: "0.5s", // Durée réduite pour mobile
      }}
    />
  );
}
