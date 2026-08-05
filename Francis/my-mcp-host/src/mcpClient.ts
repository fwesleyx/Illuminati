// my-mcp-host/src/mcpClient.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import type {
  Tool,
  CallToolResult,
  ListToolsResult,
} from "@modelcontextprotocol/sdk/types.js";

export interface MCPClientOptions {
  serverPath: string;       // path to mcp server
  allowedDirectory: string; // directory to expose
  name?: string;
  version?: string;
}

export class MCPClient {
  private client: Client;
  private transport: StdioClientTransport;

  constructor(options: MCPClientOptions) {
    this.transport = new StdioClientTransport({
      command: "node",
      args: [options.serverPath, options.allowedDirectory],
    });

    this.client = new Client(
      {
        name: options.name ?? "mcp-client",
        version: options.version ?? "1.0.0",
      },
      { capabilities: {} }
    );
  }

  async connect(): Promise<void> {
    await this.client.connect(this.transport);
    console.log("✅ Connected to MCP server");
  }

  async listTools(): Promise<Tool[]> {
    const result: ListToolsResult = await this.client.listTools();
    return result.tools;
  }

//   async callTool(
//     name: string,
//     args: Record<string, unknown>
//   ): Promise<CallToolResult> {
//     return this.client.callTool({ name, arguments: args });
//   }

  async disconnect(): Promise<void> {
    await this.client.close();
    console.log("🔌 Disconnected");
  }
}