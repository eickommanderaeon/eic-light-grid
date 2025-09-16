import type { ToolDef, ToolCall } from "./router";
import { env } from "../util/env";

type Message = { role: "system" | "user" | "assistant" | "tool"; content: string };

export type BrainResponse = {
  text?: string;
  toolCall?: ToolCall;
};

export function makeBrain() {
  const provider = (env.BRAIN_PROVIDER || "local").toLowerCase();
  if (provider === "openai") return openAIBrain();
  if (provider === "ollama") return ollamaBrain();
  return localHeuristicBrain();
}

function localHeuristicBrain() {
  return {
    async chat(messages: Message[], _tools: ToolDef[]): Promise<BrainResponse> {
      const last = messages[messages.length - 1]?.content || "";
      if (/tiktok/i.test(last) && /input\.mp4/i.test(last) && /out\.mp4/i.test(last)) {
        return { toolCall: { name: "tiktok_convert", arguments: { input: "input.mp4", output: "out.mp4" } } };
      }
      return { text: "Provide input/output video paths or enable OpenAI/Ollama in .env" };
    }
  };
}

function openAIBrain() {
  return {
    async chat(messages: Message[], tools: ToolDef[]): Promise<BrainResponse> {
      const apiKey = env.OPENAI_API_KEY;
      if (!apiKey) return { text: "Missing OPENAI_API_KEY" };
      const fetchFn: typeof fetch | undefined = (globalThis as any).fetch;
      if (!fetchFn) return { text: "Fetch API unavailable. Use Node 18+" };
      const model = env.OPENAI_MODEL || "gpt-4o-mini";
      const res = await fetchFn("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          model,
          messages,
          tools: tools.map(t => ({ type: "function", function: { name: t.name, description: t.description, parameters: t.parameters } })),
          tool_choice: "auto"
        })
      });
      if (!res.ok) return { text: `OpenAI error ${res.status}` };
      const data = await res.json();
      const msg = data.choices?.[0]?.message;
      const toolCall = msg?.tool_calls?.[0];
      if (toolCall) {
        const name = toolCall.function?.name as string;
        let args: Record<string, any> = {};
        try { args = JSON.parse(toolCall.function?.arguments || "{}"); } catch {}
        return { toolCall: { name, arguments: args } };
      }
      return { text: msg?.content || "" };
    }
  };
}

function ollamaBrain() {
  return {
    async chat(messages: Message[], _tools: ToolDef[]): Promise<BrainResponse> {
      const fetchFn: typeof fetch | undefined = (globalThis as any).fetch;
      if (!fetchFn) return { text: "Fetch API unavailable. Use Node 18+" };
      const model = env.OLLAMA_MODEL || "llama3.1";
      const res = await fetchFn("http://localhost:11434/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ model, messages, stream: false })
      });
      if (!res.ok) return { text: `Ollama error ${res.status}` };
      const data = await res.json();
      const content = data.message?.content || "";
      if (/tiktok_convert\(/i.test(content)) {
        return { toolCall: { name: "tiktok_convert", arguments: { input: "input.mp4", output: "out.mp4" } } };
      }
      return { text: content };
    }
  };
}

