// my-mcp-host/src/mcpClient.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
export class MCPClient {
    client;
    transport;
    constructor(options) {
        this.transport = new StdioClientTransport({
            command: "node",
            args: [options.serverPath, options.allowedDirectory],
        });
        this.client = new Client({
            name: options.name ?? "mcp-client",
            version: options.version ?? "1.0.0",
        }, { capabilities: {} });
    }
    async connect() {
        await this.client.connect(this.transport);
        console.log("✅ Connected to MCP server");
    }
    async listTools() {
        const result = await this.client.listTools();
        return result.tools;
    }
    //   async callTool(
    //     name: string,
    //     args: Record<string, unknown>
    //   ): Promise<CallToolResult> {
    //     return this.client.callTool({ name, arguments: args });
    //   }
    async disconnect() {
        await this.client.close();
        console.log("🔌 Disconnected");
    }
}
