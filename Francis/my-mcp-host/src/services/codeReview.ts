// src/services/codeReview.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import ollama from "ollama";

export interface CodeIssue {
  line: number;
  severity: "high" | "medium" | "low";
  message: string;
}

export interface CodeReviewResult {
  file: string;
  summary: string;
  quality_score: number;
  issues: CodeIssue[];
  improvements: string[];
  best_practices: string[];
  security: string[];
}

export interface DirectoryReviewResult {
  files: Record<string, CodeReviewResult>;
  overall_score: number;
  total_files: number;
  reviewed_files: number;
}

export class CodeReviewService {
  private client: Client;
  private transport: StdioClientTransport;
  private connected = false;
  private model: string;

  constructor(
    private projectPath: string,
    model: string = "qwen2.5-coder:1.5b"  // ✅ updated
  ) {
    this.model = model;

    this.transport = new StdioClientTransport({
        command: "node",
        args: [
            "./node_modules/@modelcontextprotocol/server-filesystem/dist/index.js",
            projectPath,
        ],
        });

    this.client = new Client(
      { name: "code-review-client", version: "1.0.0" },
      { capabilities: {} }
    );
  }

  // ── Connect ────────────────────────────────────────────────────────────────

  async connect(): Promise<void> {
    if (!this.connected) {
      await this.client.connect(this.transport);
      this.connected = true;
      console.log("✅ MCP Connected");
    }
  }

  async disconnect(): Promise<void> {
    await this.client.close();
    this.connected = false;
    console.log("🔌 Disconnected");
  }

  // ── Read file via MCP ──────────────────────────────────────────────────────

  private async readFile(filePath: string): Promise<string> {
    const result = await this.client.callTool({
    name: "read_file",
    arguments: { path: filePath },
    });
    const content = result.content as Array<{ type: string; text: string }>;
    return content.map(c => c.text).join("");
  }

  // ── List files via MCP ─────────────────────────────────────────────────────

  private async listFiles(dirPath: string): Promise<string[]> {
    const result = await this.client.callTool({
        name: "list_directory",
        arguments: { path: dirPath },
    });
    const content = result.content as Array<{ type: string; text: string }>;
    const text = content.map(c => c.text).join("\n");

    return text
      .split("\n")
      .map(f => f.trim())
      .filter(f => f.match(/\.(ts|tsx|js|jsx)$/));
  }

  // ── Review single file ─────────────────────────────────────────────────────

  async reviewFile(filePath: string): Promise<CodeReviewResult> {
    console.log(`📝 Reading: ${filePath}`);
    const code = await this.readFile(filePath);

    console.log(`🤖 Analyzing with ${this.model}...`);

    const response = await ollama.chat({
      model: this.model,
      messages: [
        {
          role: "user",
          content: `
            You are an expert code reviewer.
            Review this code and respond ONLY with valid JSON, no extra text.

            File: ${filePath}

            Code:
            \`\`\`
            ${code}
            \`\`\`

            Respond with this exact JSON structure:
            {
              "summary": "brief description",
              "quality_score": 8,
              "issues": [
                { "line": 10, "severity": "high", "message": "description" }
              ],
              "improvements": ["improvement 1"],
              "best_practices": ["violation 1"],
              "security": ["security concern 1"]
            }
          `,
        },
      ],
      format: "json",   // ✅ forces JSON output
      options: {
        temperature: 0.1,  // ✅ low temp = consistent output
        num_ctx: 4096,     // ✅ context window
      },
    });

    const parsed = JSON.parse(
      response.message.content
    ) as Omit<CodeReviewResult, "file">;

    return {
      file: filePath,
      ...parsed,
    };
  }

  // ── Review directory ───────────────────────────────────────────────────────

  async reviewDirectory(dirPath: string): Promise<DirectoryReviewResult> {
    console.log(`📁 Listing files in: ${dirPath}`);
    const files = await this.listFiles(dirPath);
    console.log(`📋 Found ${files.length} files`);

    const reviews: Record<string, CodeReviewResult> = {};

    for (const file of files) {
      try {
        reviews[file] = await this.reviewFile(file);
        console.log(
          `✅ Done: ${file} → Score: ${reviews[file].quality_score}/10`
        );
      } catch (err) {
        console.error(`❌ Failed: ${file}`, err);
      }
    }

    const scores = Object.values(reviews).map(r => r.quality_score);
    const avgScore = scores.length
      ? scores.reduce((a, b) => a + b, 0) / scores.length
      : 0;

    return {
      files: reviews,
      overall_score: Math.round(avgScore * 10) / 10,
      total_files: files.length,
      reviewed_files: Object.keys(reviews).length,
    };
  }
}