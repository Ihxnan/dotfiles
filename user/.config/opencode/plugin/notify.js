import { exec } from "child_process";

export default async () => {
  return {
    event: async ({ event }) => {
      if (event.type === "permission.asked") {
        exec('dms notify "opencode" "需要你的确认" --app opencode --timeout 8000');
      }

      if (event.type === "session.idle") {
        exec('dms notify "opencode" "任务已完成" --app opencode --timeout 8000');
      }
    },
  };
};
