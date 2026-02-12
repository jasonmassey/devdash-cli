#!/usr/bin/env node
"use strict";

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const readline = require("readline");

// Skip in non-interactive environments (CI, piped, no TTY)
if (!process.stdin.isTTY || process.env.CI || process.env.NONINTERACTIVE) {
  console.log("\ndevdash installed successfully!");
  console.log("Run 'devdash alias-setup' to add a 'dd' shortcut.\n");
  process.exit(0);
}

function detectShellConfig() {
  const shell = path.basename(process.env.SHELL || "/bin/bash");
  switch (shell) {
    case "zsh":
      return path.join(process.env.HOME, ".zshrc");
    case "fish":
      return path.join(
        process.env.HOME,
        ".config",
        "fish",
        "config.fish"
      );
    case "bash":
    default: {
      const bashrc = path.join(process.env.HOME, ".bashrc");
      if (fs.existsSync(bashrc)) return bashrc;
      return path.join(process.env.HOME, ".bash_profile");
    }
  }
}

function aliasAlreadySet(rcFile) {
  try {
    const content = fs.readFileSync(rcFile, "utf8");
    return content.includes("alias dd=devdash");
  } catch {
    return false;
  }
}

async function main() {
  const rcFile = detectShellConfig();
  const shell = path.basename(process.env.SHELL || "/bin/bash");

  console.log("");
  console.log("╔══════════════════════════════════════════════════════╗");
  console.log("║  devdash installed successfully!                     ║");
  console.log("╚══════════════════════════════════════════════════════╝");
  console.log("");

  if (aliasAlreadySet(rcFile)) {
    console.log(`'dd' alias already configured in ${rcFile}`);
    console.log("You're all set! Run 'devdash help' to get started.\n");
    return;
  }

  console.log(
    "Would you like to alias 'dd' → 'devdash' for shorter commands?"
  );
  console.log("");
  console.log(
    "  ⚠  This shadows /usr/bin/dd (Unix disk copy utility)."
  );
  console.log("     Only do this if you don't use that tool.");
  console.log("");

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const answer = await new Promise((resolve) => {
    rl.question("Add alias? [Y/n] ", (ans) => {
      rl.close();
      resolve(ans.trim().toLowerCase() || "y");
    });
  });

  if (answer === "y" || answer === "yes") {
    const aliasLine =
      shell === "fish"
        ? "alias dd devdash"
        : "alias dd=devdash";

    const comment = "# devdash: alias dd -> devdash";
    fs.appendFileSync(rcFile, `\n${comment}\n${aliasLine}\n`);

    console.log("");
    console.log(`Added to ${rcFile}.`);
    console.log(
      `Run 'source ${rcFile}' or restart your terminal.`
    );
  } else {
    console.log("");
    console.log(
      "Skipped. You can always run 'devdash alias-setup' later."
    );
  }

  console.log("");
  console.log("Run 'devdash help' to get started.");
  console.log("");
}

main().catch((err) => {
  // Don't fail the install if postinstall prompt fails
  console.error("postinstall note:", err.message);
  console.log("\ndevdash installed successfully!");
  console.log("Run 'devdash alias-setup' to add a 'dd' shortcut.\n");
});
