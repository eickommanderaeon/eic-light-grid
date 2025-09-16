import Fastify from "fastify";
import "dotenv/config";
const app = Fastify();
app.get("/", async () => ({ ok: true, name: "LGA API" }));
app.post("/run", async (req, res) => {
  const body = (req.body || {}) as { input?: string };
  return { ok: true, echo: body.input ?? "Hello" };
});
app.listen({ port: 7777 }).then(() => console.log("LGA API on :7777"));
