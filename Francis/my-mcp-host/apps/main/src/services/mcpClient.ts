// apps/main/src/services/mcpClient.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

export class MCPClient {
  private client: Client;
  private transport: StdioClientTransport;

  constructor(allowedDirectory: string = "./") {
    this.transport = new StdioClientTransport({
      command: "node",
      args: [
        // Point to my-mcp-host node_modules
        "C:\\Users\\fwesleyx\\source\\repos\\Illuminati\\Francis\\my-mcp-host\\node_modules\\.bin\\mcp-server-filesystem",
        allowedDirectory,
      ],
    });

    this.client = new Client(
      { name: "app-mcp-client", version: "1.0.0" },
      { capabilities: {} }
    );
  }

  async connect(): Promise<void> {
    await this.client.connect(this.transport);
    console.log("✅ Connected to MCP server");
  }

  async listTools() {
    const result = await this.client.listTools();
    return result.tools;
  }

  async callTool(name: string, args: Record<string, unknown>) {
    return this.client.callTool({ name, arguments: args });
  }

  async listResources() {
    const result = await this.client.listResources();
    return result.resources;
  }

  async readResource(uri: string) {
    return this.client.readResource({ uri });
  }

  async disconnect(): Promise<void> {
    await this.client.close();
    console.log("🔌 Disconnected");
  }
}