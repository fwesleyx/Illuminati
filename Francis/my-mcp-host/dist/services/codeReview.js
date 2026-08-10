// src/services/codeReview.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import ollama from "ollama";
export class CodeReviewService {
    projectPath;
    client;
    transport;
    connected = false;
    model;
    constructor(projectPath, model = "qwen2.5-coder:1.5b" // ✅ updated
    ) {
        this.projectPath = projectPath;
        this.model = model;
        this.transport = new StdioClientTransport({
            command: "node",
            args: [
                "./node_modules/.bin/mcp-server-filesystem",
                projectPath,
            ],
        });
        this.client = new Client({ name: "code-review-client", version: "1.0.0" }, { capabilities: {} });
    }
    // ── Connect ────────────────────────────────────────────────────────────────
    async connect() {
        if (!this.connected) {
            await this.client.connect(this.transport);
            this.connected = true;
            console.log("✅ MCP Connected");
        }
    }
    async disconnect() {
        await this.client.close();
        this.connected = false;
        console.log("🔌 Disconnected");
    }
    // ── Read file via MCP ──────────────────────────────────────────────────────
    async readFile(filePath) {
        const result = await this.client.callTool({
            name: "read_file",
            arguments: { path: filePath },
        });
        const content = result.content;
        return content.map(c => c.text).join("");
    }
    // ── List files via MCP ─────────────────────────────────────────────────────
    async listFiles(dirPath) {
        const result = await this.client.callTool({
            name: "list_directory",
            arguments: { path: dirPath },
        });
        const content = result.content;
        const text = content.map(c => c.text).join("\n");
        return text
            .split("\n")
            .map(f => f.trim())
            .filter(f => f.match(/\.(ts|tsx|js|jsx)$/));
    }
    // ── Review single file ─────────────────────────────────────────────────────
    async reviewFile(filePath) {
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
            format: "json", // ✅ forces JSON output
            options: {
                temperature: 0.1, // ✅ low temp = consistent output
                num_ctx: 4096, // ✅ context window
            },
        });
        const parsed = JSON.parse(response.message.content);
        return {
            file: filePath,
            ...parsed,
        };
    }
    // ── Review directory ───────────────────────────────────────────────────────
    async reviewDirectory(dirPath) {
        console.log(`📁 Listing files in: ${dirPath}`);
        const files = await this.listFiles(dirPath);
        console.log(`📋 Found ${files.length} files`);
        const reviews = {};
        for (const file of files) {
            try {
                reviews[file] = await this.reviewFile(file);
                console.log(`✅ Done: ${file} → Score: ${reviews[file].quality_score}/10`);
            }
            catch (err) {
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
