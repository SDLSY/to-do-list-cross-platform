// PocketBase 服务端 Hook：响应前端一键触发备份到 GitHub 请求
routerAdd("POST", "/api/custom/backup", (c) => {
    try {
        // 执行自动化备份脚本
        $os.cmd("/home/testcc/to_list_linux_windows_android/backup/backup_to_github.sh").run();
        return c.json(200, {
            success: true,
            message: "备份成功！结构化数据与 Markdown 日报已推送到 GitHub。"
        });
    } catch (e) {
        return c.json(500, {
            success: false,
            error: "执行备份失败: " + e.message
        });
    }
});
