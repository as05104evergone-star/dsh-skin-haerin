# _upstream/ —— 上游 token 表（仅供预览）

这三个 CSS 是从本机安装的 DSH 客户端里抽出来的，**不是手写的**：

| 文件 | 来源 |
| --- | --- |
| `design-platform.css` | `@deepseek-ai/dsh-client-ui-theme` → `design-platform.css` |
| `gradient-shadow-text.css` | 同包 → `gradient-shadow-text.css` |
| `scrollbar.css` | 同包 → `scrollbar.css` |

客户端把这些样式表以字符串内联在 `lib/client.js` 里，运行时再注入 `<head>`；
`tools/extract-upstream.ps1` 把它们还原出来，用在这里只有一个目的：
让 `preview.html` 的底色、描边、阴影与真实客户端**完全一致**，
这样预览页里调出来的效果就是客户端里的效果。

- **皮肤运行时不依赖这些文件**：真实客户端自带同样的 token 表，`haerin.css` 只是覆盖它。
- **不要直接改这里**：它们是上游产物，改了会和客户端对不上。
  DSH 升级后跑一次 `tools\extract-upstream.ps1` 即可刷新。
- 许可：这些样式表来自 DSH（MIT，© DeepSeek）。仓库根目录的 MIT 许可覆盖的是本皮肤
  自己的代码与矢量素材。
