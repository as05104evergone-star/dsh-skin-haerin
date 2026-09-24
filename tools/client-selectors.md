# 客户端结构选择器备忘

皮肤不打包任何组件，只靠 CSS 选择器挂到宿主结构上。客户端用的是带哈希的
CSS Module（例如 `qNbT7G_sidebarCol`），**哈希每次构建都会变，后缀是稳定的**，
所以 skin 一律用 `[class*="_后缀"]` 命中，而不是写死类名。另外宿主暴露了一批
`data-*` 钩子，它们比类名更稳定，优先使用。

## 皮肤实际用到的钩子

| 目标 | 选择器 | 宿主里的东西 | 它的背景 token |
| --- | --- | --- | --- |
| 整个网格 | `[class*="_frame"]` | AppFrame.frame | `--dsw-alias-bg-base` |
| 左栏 | `[class*="_sidebarCol"]` | AppFrame.sidebarCol | `--dsw-specific-sidebar-fill` |
| 左栏内容根 | `[class*="_sidebarCol"] > [class*="_root"]` | SidebarRoot.root | 同上（皮肤里放行成透明，避免两层同色叠暗） |
| 中栏 | `[class*="_centerCol"]` | AppFrame.centerCol | 无背景 |
| 会话根 | `[class*="_0cyzDW"]` 形如 `[class*="_root"]`（不写死哈希，靠 `data-chat-flow` 亦可） | ConversationRoot.root | `--dsw-alias-bg-base` |
| 右栏 | `[class*="_rightbarCol"] [class*="_panel"]` | SidebarRight.panel | `--dsw-alias-bg-base` |
| 菜单/下拉 | `[class*="_menu"]`（排除 `_menuOpen` / `_menuAnchor` / `_menuAction` / `_menuStatus`） | ModelSelect / Jobs / Schedule / Commands … 的 menu | `--dsw-specific-menu` |
| 浮层视口 | `[class*="_viewport"]` | MenuView.viewport / PopupSelectView.viewport | `--dsw-specific-menu` |
| 输入卡 | `[data-composer-card]`、`[class*="_composerSeat"] [class*="_card"]` | InputBar.card | `--dsw-specific-input-major` |
| 用户气泡 | `[class*="_bubble"]` | ChatView.bubble / GoalBar.bubble | `--dsw-specific-bubble` |
| 模态遮罩 | `[class*="_mask"]` | SettingsGeneral.mask / Attachment.mask | `--dsw-alias-bg-mask-1` |
| 停靠条 | `[class*="_dock"]` | QueueDock.dock / GoalBar.dock | `--dsw-specific-tip` |

## 其它可用的稳定钩子（还没用上，留着扩展）

`data-sidebar-collapsed`、`data-rightbar-col`、`data-rightbar-collapsed`、
`data-shell-overlay`、`data-chat-flow`、`data-turn`、`data-turn-process`、
`data-conversation-scroll`、`data-conversation-header-corner`、
`data-queue-dock`、`data-goal-bar`、`data-todo-*`、`data-cordis-panel`、
`data-sidebar-right-panel`、`data-document-preview`、`data-files-root`。

## 重新挖一遍

客户端把每个模块的 CSS 以 `const css$N = "..."` / `var X_css_default = "..."` 的
形式内联在 `@deepseek-ai/dsh-client-ui-*/lib/client.js` 里，类名映射紧随其后：

```powershell
# 列出所有模块的类名键（centerCol / sidebarCol / panel / menu …）
$root = "$env:DSH_HOME\profiles\node_modules\@deepseek-ai"
Get-ChildItem $root -Directory | ForEach-Object {
  $f = Join-Path $_.FullName 'lib\client.js'
  if (Test-Path $f) {
    $t = [IO.File]::ReadAllText($f, (New-Object Text.UTF8Encoding($false)))
    [regex]::Matches($t, '(\w+)_module_css_default = \{([^}]*)\}') | ForEach-Object {
      "$($_.Groups[1].Value) : $($_.Groups[2].Value)"
    }
  }
}
```
