import { makeBrain } from "./core/brain";
import { SYSTEM_PERSONA } from "./core/persona";
import { routeTool, toolsToOpenAIFunctions } from "./core/router";

async function main() {
  const brain = makeBrain();
  const tools = toolsToOpenAIFunctions();
  const messages = [
    { role: "system", content: SYSTEM_PERSONA },
    { role: "user", content: "Convert input.mp4 to TikTok spec and save as out.mp4" },
  ];
  const res = await brain.chat(messages as any, tools);
  if (res.toolCall) {
    try {
      const toolRes = await routeTool(res.toolCall.name as any, { input: "input.mp4", output: "out.mp4" });
      console.log("TOOL RESULT:", toolRes);
    } catch (err: any) {
      console.error("Tool error:", err?.message || String(err));
    }
  } else {
    console.log("ASSISTANT:", res.text);
  }
}

main().catch(console.error);

