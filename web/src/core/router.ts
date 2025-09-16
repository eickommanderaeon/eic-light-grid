import { tiktokConvert, TikTokConvertArgs } from "../tools/tiktok";

export type ToolCall = { name: string; arguments: Record<string, any> };

export type ToolDef = {
  name: string;
  description: string;
  parameters: any;
};

export function toolsToOpenAIFunctions(): ToolDef[] {
  return [
    {
      name: "tiktok_convert",
      description: "Convert a video to TikTok 9:16 (1080x1920) with light enhancement.",
      parameters: {
        type: "object",
        properties: {
          input: { type: "string" },
          output: { type: "string" },
          crf: { type: "number" },
          preset: { type: "string" },
          fps: { type: "number" }
        },
        required: ["input", "output"],
        additionalProperties: false
      }
    }
  ];
}

export async function routeTool(name: string, args: Record<string, any>) {
  switch (name) {
    case "tiktok_convert":
      return await tiktokConvert(args as TikTokConvertArgs);
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

