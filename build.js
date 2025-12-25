#!/usr/bin/env node

const { execSync } = require("child_process");

// Determine if we're in production/CI environment or development
const isProduction =
  process.env.RAILS_ENV === "production" ||
  process.env.CI === "true" ||
  process.env.NODE_ENV === "production";

// Base esbuild command (use npx to ensure esbuild is found)
const baseCommand =
  "npx esbuild app/javascript/*.* --bundle --sourcemap --format=esm --outdir=app/assets/builds --public-path=/assets";

// Add watch flag only in development
const command = isProduction ? baseCommand : `${baseCommand} --watch=forever`;

console.log(
  `Building JavaScript assets (${
    isProduction ? "production" : "development"
  } mode)...`
);
console.log(`Command: ${command}`);

try {
  execSync(command, { stdio: "inherit" });
} catch (error) {
  console.error("Build failed:", error.message);
  process.exit(1);
}
