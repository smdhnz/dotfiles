import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const number = (value: number) => Math.round(value).toLocaleString("en-US");
const compactNumber = (value: number) =>
  value >= 1_000_000
    ? `${Number((value / 1_000_000).toFixed(1))}M`
    : value >= 1_000
      ? `${Number((value / 1_000).toFixed(1))}k`
      : `${value}`;

export default function (pi: ExtensionAPI) {
  let dirty = false;
  let refreshFooter = () => {};
  let cwd = "";

  const refreshDirty = async () => {
    if (!cwd) return;
    const result = await pi.exec("git", ["status", "--porcelain"], { cwd });
    dirty = result.code === 0 && result.stdout.trim() !== "";
    refreshFooter();
  };

  pi.on("agent_settled", refreshDirty);

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    cwd = ctx.sessionManager.getCwd();
    await refreshDirty();

    ctx.ui.setFooter((tui, theme, footerData) => {
      refreshFooter = () => tui.requestRender();
      const unsubscribe = footerData.onBranchChange(() => void refreshDirty());

      return {
        dispose: unsubscribe,
        invalidate() {},
        render(width: number): string[] {
          let input = 0;
          let output = 0;
          let cacheRead = 0;
          let cacheWrite = 0;
          let cost = 0;

          for (const entry of ctx.sessionManager.getEntries()) {
            if (entry.type !== "message" || entry.message.role !== "assistant")
              continue;
            const usage = (entry.message as AssistantMessage).usage;
            input += usage.input;
            output += usage.output;
            cacheRead += usage.cacheRead;
            cacheWrite += usage.cacheWrite;
            cost += usage.cost.total;
          }

          const context = ctx.getContextUsage();
          const contextWindow =
            context?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextPart =
            context?.percent == null
              ? `?/${compactNumber(contextWindow)} (auto)`
              : `${context.percent.toFixed(1)}%/${compactNumber(contextWindow)} (auto)`;
          const separator = theme.fg("dim", " | ");
          const usageParts = [
            theme.fg("accent", `Input: ${number(input)}`),
            theme.fg("success", `Output: ${number(output)}`),
            theme.fg("mdLink", `Cache read: ${number(cacheRead)}`),
            theme.fg("warning", `Cache write: ${number(cacheWrite)}`),
          ];
          usageParts.push(
            theme.fg(
              "text",
              `Total: ${number(input + output + cacheRead + cacheWrite)}`,
            ),
          );
          if (cost)
            usageParts.push(theme.fg("warning", `Cost: $${cost.toFixed(3)}`));
          const contextColor =
            context?.percent != null && context.percent > 90
              ? "error"
              : context?.percent != null && context.percent > 70
                ? "warning"
                : "accent";
          usageParts.push(theme.fg(contextColor, contextPart));

          const branch = footerData.getGitBranch();
          const sessionName = ctx.sessionManager.getSessionName();
          const location =
            `${branch ? `(${branch}${dirty ? "*" : ""}) ` : ""}${ctx.sessionManager.getCwd()}` +
            (sessionName ? ` | Session: ${sessionName}` : "");

          const modelName = ctx.model
            ? `(${ctx.model.provider}) ${ctx.model.id}`
            : "no-model";
          const thinking =
            ctx.thinkingLevel === "off" ? "thinking off" : ctx.thinkingLevel;
          const model =
            theme.fg("text", modelName) +
            (ctx.model?.reasoning
              ? theme.fg("dim", " • ") + theme.fg("accent", thinking)
              : "");
          const left = usageParts.join(separator);
          const padding = " ".repeat(
            Math.max(2, width - visibleWidth(left) - visibleWidth(model)),
          );
          const statuses = [...footerData.getExtensionStatuses().values()].join(
            separator,
          );

          return [theme.fg("dim", location), left + padding + model, statuses]
            .filter(Boolean)
            .map((line) =>
              truncateToWidth(line, width, theme.fg("dim", "...")),
            );
        },
      };
    });
  });
}
