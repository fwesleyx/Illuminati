// src/host.ts
import * as dotenv from "dotenv";
dotenv.config();

import { CodeReviewService } from "./services/codeReview.js";
import * as readline from "node:readline/promises";

const PROJECT_PATH =
  process.env.PROJECT_PATH ??
  "C:\\Users\\fwesleyx\\source\\repos\\Illuminati\\Francis\\app";

const MODEL = process.env.OLLAMA_MODEL ?? "qwen2.5-coder:1.5b";

const service = new CodeReviewService(PROJECT_PATH, MODEL);

async function showMenu(rl: readline.Interface): Promise<void> {
  console.log(`
  ┌──────────────────────────────┐
  │   🔍 MCP Code Review Tool   │
  ├──────────────────────────────┤
  │  1. Review a file            │
  │  2. Review a directory       │
  │  3. Exit                     │
  └──────────────────────────────┘
  `);

  const choice = await rl.question("Choose: ");

  switch (choice.trim()) {
    case "1": {
      const filePath = await rl.question("File path: ");
      const result = await service.reviewFile(filePath.trim());

      console.log(`
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📄 File     : ${result.file}
  ⭐ Score    : ${result.quality_score}/10
  📝 Summary  : ${result.summary}
      `);

      if (result.issues.length) {
        console.log("⚠️  Issues:");
        result.issues.forEach(i =>
          console.log(
            `   [${i.severity.toUpperCase()}] Line ${i.line}: ${i.message}`
          )
        );
      }

      if (result.improvements.length) {
        console.log("\n✅ Improvements:");
        result.improvements.forEach(i => console.log(`   • ${i}`));
      }

      if (result.security.length) {
        console.log("\n🔒 Security:");
        result.security.forEach(s => console.log(`   • ${s}`));
      }

      break;
    }

    case "2": {
      const dirPath = await rl.question("Directory path: ");
      const result = await service.reviewDirectory(dirPath.trim());

      console.log(`
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📁 Directory Review Complete
  ⭐ Overall Score  : ${result.overall_score}/10
  📋 Files Reviewed : ${result.reviewed_files}/${result.total_files}
      `);

      Object.entries(result.files).forEach(([file, review]) => {
        console.log(
          `  ${review.quality_score >= 7 ? "✅" : "⚠️"} ${file} → ${review.quality_score}/10`
        );
      });

      break;
    }

    case "3":
      return;

    default:
      console.log("❌ Invalid option");
  }

  await showMenu(rl);
}

async function main(): Promise<void> {
  try {
    console.log("🚀 Starting MCP Code Review Tool...");
    console.log(`📁 Project : ${PROJECT_PATH}`);
    console.log(`🤖 Model   : ${MODEL}`);

    await service.connect();

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    await showMenu(rl);
    rl.close();

  } catch (error) {
    console.error(
      "❌ Error:",
      error instanceof Error ? error.message : error
    );
    process.exit(1);
  } finally {
    await service.disconnect();
  }
}

main();