/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("todos");

  const initialTasks = [
    {
      title: "欢迎使用跨平台待办工具 🚀",
      description: "支持 Linux、Windows、Android 三端实时同步！",
      status: "todo",
      priority: 2, // 高
      order: 1000,
    },
    {
      title: "测试看板拖拽与状态流转",
      description: "在桌面端拖拽卡片，或直接点击状态按钮将卡片移至“进行中”",
      status: "in_progress",
      priority: 1, // 中
      order: 2000,
    },
    {
      title: "后端服务 PocketBase 启动与配置",
      description: "单二进制文件运行，内置 SQLite，提供实时 WebSocket / SSE 广播",
      status: "done",
      priority: 0, // 低
      order: 3000,
    }
  ];

  for (const task of initialTasks) {
    const record = new Record(collection);
    record.set("title", task.title);
    record.set("description", task.description);
    record.set("status", task.status);
    record.set("priority", task.priority);
    record.set("order", task.order);
    app.save(record);
  }
}, (app) => {
  // rollback if needed
});
