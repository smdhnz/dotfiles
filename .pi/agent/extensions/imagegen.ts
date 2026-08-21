import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { homedir } from "node:os";

const CODEX_IMAGES_URL = "https://chatgpt.com/backend-api/codex/images";
const DEFAULT_IMAGE_MODEL = "gpt-image-2";
const JWT_CLAIM_PATH = "https://api.openai.com/auth";
const MAX_EDIT_IMAGES = 5;

type ImagegenParams = {
  prompt: string;
  outputPath?: string;
  referenced_image_paths?: string[];
};

type ImageResponse = {
  data?: Array<{ b64_json?: string }>;
};

function decodeJwtPayload(token: string): any {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid OpenAI Codex access token");
  const payload = parts[1] ?? "";
  const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return JSON.parse(Buffer.from(padded, "base64").toString("utf8"));
}

function getAccountId(token: string): string {
  const accountId = decodeJwtPayload(token)?.[JWT_CLAIM_PATH]?.chatgpt_account_id;
  if (!accountId || typeof accountId !== "string") {
    throw new Error("Failed to extract chatgpt_account_id from OpenAI Codex access token");
  }
  return accountId;
}

function resolvePath(cwd: string, requested: string): string {
  const expanded = requested.startsWith("~/") ? join(homedir(), requested.slice(2)) : requested;
  return isAbsolute(expanded) ? expanded : resolve(cwd, expanded);
}

function resolveOutputPath(cwd: string, requested: string | undefined): string {
  const fallback = join(homedir(), ".pi", "agent", "generated_images", `${new Date().toISOString().replace(/[:.]/g, "-")}-${randomUUID().slice(0, 8)}.png`);
  let out = requested?.trim() ? resolvePath(cwd, requested.trim()) : fallback;
  if (!/\.png$/i.test(out)) out = `${out}.png`;
  return out;
}

function mimeForImagePath(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".gif")) return "image/gif";
  return "image/png";
}

async function imageDataUrl(path: string): Promise<string> {
  const bytes = await readFile(path);
  return `data:${mimeForImagePath(path)};base64,${bytes.toString("base64")}`;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "imagegen",
    label: "Image Gen",
    description: "Generate or edit raster images using the OpenAI Codex/ChatGPT login-backed Images API and save the bitmap to disk.",
    promptSnippet: "Generate or edit raster bitmap images with OpenAI Codex image generation and save them to disk",
    promptGuidelines: [
      "Use imagegen when the user asks to create or edit a raster image/photo/illustration/mockup/texture/sprite.",
      "Do not use imagegen for SVG/vector/code-native graphics.",
      "Provide a concrete prompt and outputPath inside the workspace for project assets. Report the saved path.",
    ],
    parameters: Type.Object({
      prompt: Type.String({ description: "Image generation or edit instruction." }),
      outputPath: Type.Optional(Type.String({ description: "Where to save the generated PNG. Relative paths resolve from cwd." })),
      referenced_image_paths: Type.Optional(Type.Array(Type.String(), {
        maxItems: MAX_EDIT_IMAGES,
        description: "Up to five local image paths to use as edit targets or references.",
      })),
    }),
    async execute(_toolCallId, params: ImagegenParams, signal, onUpdate, ctx) {
      const token = await ctx.modelRegistry.getApiKeyForProvider("openai-codex");
      if (!token) {
        return { isError: true, content: [{ type: "text", text: "OpenAI Codex login credentials are not available. Run pi login for openai-codex first." }] };
      }
      const inputPaths = params.referenced_image_paths ?? [];
      if (inputPaths.length > MAX_EDIT_IMAGES) {
        return { isError: true, content: [{ type: "text", text: `referenced_image_paths must contain at most ${MAX_EDIT_IMAGES} images.` }] };
      }
      const isEdit = inputPaths.length > 0;
      const outPath = resolveOutputPath(ctx.cwd, params.outputPath);
      const body: Record<string, unknown> = {
        prompt: params.prompt,
        background: "auto",
        model: DEFAULT_IMAGE_MODEL,
        quality: "auto",
        size: "auto",
      };
      if (isEdit) {
        body.images = await Promise.all(inputPaths.map(async (path) => ({ image_url: await imageDataUrl(resolvePath(ctx.cwd, path)) })));
      }

      onUpdate?.({ content: [{ type: "text", text: `Calling OpenAI Codex ${isEdit ? "image edit" : "image generation"}...` }] });
      const requestId = randomUUID();
      const response = await fetch(`${CODEX_IMAGES_URL}/${isEdit ? "edits" : "generations"}`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "chatgpt-account-id": getAccountId(token),
          originator: "pi",
          "User-Agent": "pi imagegen extension",
          "content-type": "application/json",
          "x-codex-image-turn-id": requestId,
          "x-client-request-id": requestId,
        },
        body: JSON.stringify(body),
        signal,
      });
      if (!response.ok) {
        const text = await response.text().catch(() => "");
        return { isError: true, content: [{ type: "text", text: `Codex Images API HTTP ${response.status}: ${text || response.statusText}` }], details: { status: response.status } };
      }

      const result = await response.json() as ImageResponse;
      const b64 = result.data?.[0]?.b64_json;
      if (!b64) throw new Error("Codex Images API returned no image data");
      await mkdir(dirname(outPath), { recursive: true });
      await writeFile(outPath, Buffer.from(b64, "base64"));
      return {
        content: [{ type: "text", text: `Generated image saved to ${outPath}` }],
        details: { savedPath: outPath, model: body.model },
      };
    },
  });
}
