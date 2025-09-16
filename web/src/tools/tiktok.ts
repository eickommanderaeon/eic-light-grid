import { spawn } from "child_process";

export type TikTokConvertArgs = {
  input: string;
  output: string;
  crf?: number;
  preset?: string;
  fps?: number;
};

const buildFilter = (fps: number) => [
  "crop=in_w:in_h-ih*0.22:0:ih*0.10",
  "scale=1080:1920:flags=lanczos:force_original_aspect_ratio=decrease",
  "pad=1080:1920:(1080-iw)/2:(1920-ih)/2",
  "unsharp=5:5:0.7:5:5:0",
  "eq=contrast=1.05:brightness=0.02:saturation=1.08",
  "setsar=1",
  `fps=${fps}`,
].join(",");

export async function tiktokConvert({ input, output, crf = 18, preset = "slow", fps = 30 }: TikTokConvertArgs) {
  const vf = buildFilter(fps);
  const args = [
    "-y",
    "-i", input,
    "-vf", vf,
    "-c:v", "libx264",
    "-profile:v", "high",
    "-level", "4.2",
    "-pix_fmt", "yuv420p",
    "-preset", preset,
    "-crf", String(crf),
    "-movflags", "+faststart",
    "-c:a", "aac",
    "-b:a", "192k",
    "-ar", "48000",
    output,
  ];
  const code = await spawnAsync("ffmpeg", args);
  if (code !== 0) throw new Error(`ffmpeg exited with code ${code}`);
  return { ok: true, output };
}

function spawnAsync(cmd: string, args: string[]) {
  return new Promise<number>((resolve, reject) => {
    const p = spawn(cmd, args, { stdio: "inherit" });
    p.on("error", reject);
    p.on("close", (code) => resolve(code ?? 1));
  });
}

