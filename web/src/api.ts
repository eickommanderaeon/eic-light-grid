import http from "http";
import { makeBrain } from "./core/brain";
import { SYSTEM_PERSONA } from "./core/persona";
import { toolsToOpenAIFunctions, routeTool } from "./core/router";

const PORT = 7777;
const brain = makeBrain();
const tools = toolsToOpenAIFunctions();

type RunBody = { input?: string; toolArgs?: Record<string, any> };

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === "POST" && req.url === "/run") {
      const raw = await readBody(req);
      const body = (raw ? JSON.parse(raw) : {}) as RunBody;
      const input = body.input || "Convert input.mp4 to TikTok spec and save as out.mp4";
      const messages = [
        { role: "system", content: SYSTEM_PERSONA },
        { role: "user", content: input },
      ];
      const reply = await brain.chat(messages as any, tools);
      if ((reply as any).toolCall) {
        const tc = (reply as any).toolCall;
        try {
          const result = await routeTool(tc.name as any, { ...(tc.arguments || {}), ...(body.toolArgs || {}) });
          return json(res, 200, { tool: tc.name, result });
        } catch (err: any) {
          return json(res, 500, { error: err?.message || String(err) });
        }
      }
      return json(res, 200, { text: reply.text });
    }
    json(res, 404, { error: "Not found" });
  } catch (err: any) {
    json(res, 500, { error: err?.message || String(err) });
  }
});

server.listen(PORT, () => console.log(`LGA API on :${PORT}`));

function readBody(req: http.IncomingMessage) {
  return new Promise<string>((resolve) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk));
    req.on("end", () => resolve(data));
  });
}

function json(res: http.ServerResponse, code: number, obj: any) {
  const body = JSON.stringify(obj);
  res.writeHead(code, { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body) });
  res.end(body);
}

