# 自定义指南

这套皮肤没有构建步骤：`haerin-skin/` 里的文件就是最终产物。
改完重跑一次安装、刷新一次界面，就能看到结果。

```powershell
install.cmd          # 复制到 dist
# 然后：托盘图标右键 →「重新加载界面」
```

想边改边看，先开 `haerin-skin/preview.html`——它照抄了客户端的类名，
磨砂、壁纸、开关都跟在客户端里一样，而且改完只要按 F5：

```
preview.html?skinmode=day      强制看昼
preview.html?skinmode=night    强制看夜
```

---

## 1. 换配色

打开 `haerin-skin/haerin.css`。文件里有**两个模式块**：

- `html[data-haerin-skin="on"] body { … }` → 昼
- `html[data-haerin-skin="on"][data-haerin-mode="night"] body, …` → 夜

每个块从上到下是三段：**原色阶梯 → 映射层 → 语义层微调**。改色主要动第 1 段和第 3 段。

### 1.1 换整体色调（最省事）

每个块顶部的三条阶梯就是全部颜色的来源，整条替换即可：

```css
  /* —— 海雾青：替换 neutral-bluish 阶梯（表面 / 文字） —— */
  --dsw-static-neutral-bluish-00: #fbfcff;    /* 最亮：白天的卡片 */
  --dsw-static-neutral-bluish-50: #f4f8fd;
  …
  --dsw-static-neutral-bluish-1000: #080c12;  /* 最暗：白天的正文 */
```

- `neutral-bluish-*`：表面与文字，**19 级**，从最亮（00）到最暗（1000）
- `deepseek-*`：链接、信息、引用（丹宁蓝这一族）
- `neutral-*`：内联代码、滚动条（冷灰这一族）

> **要点**：白天用的是阶梯的**亮端**（卡片取 00/50，正文取 1000），
> 夜里用的是**暗端**（页面取 950，正文取 50）。所以换阶梯时两端都要照顾到。
> 拿不准就保持"亮端偏冷/暖、暗端对比够"这个形状。

### 1.2 换强调色（腮红 / 胭脂 / 链接 / 主按钮）

同块下面「语义层微调」那一段：

```css
  --dsw-alias-brand-primary: #131b26;                              /* 主按钮、品牌块 */
  --dsw-alias-brand-primary-new-colorprimary-new-color: #c97f8e;   /* 强调色（腮红） */
  --dsw-alias-link: …                                              /* 链接（昼走阶梯，夜显式指定） */
  --dsw-specific-bubble: rgb(230 240 252 / 68%);                   /* 用户气泡 */
```

### 1.3 夜色的暖色为什么是显式写的

因为一条阶梯的暗端**同时**是白天的正文色。白天要冷、夜里要暖，一条阶梯做不到两头，
所以夜块里把 `--dsw-alias-label-primary/secondary/tertiary/caption`、内联代码、
toast/tooltip、气泡这些 token 单独钉了值。**改夜色的文字色，直接改这一批。**

### 1.4 换色示例：把它变成"青柠"

```css
/* 昼块 */
--dsw-static-neutral-bluish-00: #fbfff8;
--dsw-static-neutral-bluish-50: #f3fbec;
--dsw-static-neutral-bluish-100: #e4f2d9;
--dsw-static-neutral-bluish-300: #b7d3a1;
--dsw-static-neutral-bluish-600: #6b8455;
--dsw-static-neutral-bluish-1000: #0d1408;
--dsw-static-deepseek-500: #5f8a2e;      /* 链接 */
--dsw-alias-brand-primary-new-colorprimary-new-color: #a8c93a;  /* 强调 */
```

改完顺手把 `--hj-wall-color`（壁纸底色）也改成同一族，不然底色和表面会打架。

---

## 2. 换背景

背景是画在 `<html>` 上的 5 层，顺序写在 `haerin.css` 的 `--hj-wall` 里
（**自上而下**，第一项在最上面）：

```css
  --hj-wall:
    url("art/grain.svg"),        /* 颗粒 */
    url("art/day-pixel.svg"),    /* 像素贴纸 */
    url("art/dither-day.svg"),   /* 抖动网点 */
    url("art/day-photo.jpg"),    /* 照片（可以没有） */
    url("art/day-mist.svg");     /* 晕染底 */
  --hj-wall-size: 180px 180px, 1600px 1000px, 4px 4px, auto 104%, cover;
  --hj-wall-pos: center, center, center, right -3vw center, center;
  --hj-wall-repeat: repeat, no-repeat, repeat, no-repeat, no-repeat;
```

### 2.1 只换图，不改结构

把你的 SVG 覆盖成同名文件（`day-mist.svg` 等）就行。

### 2.2 换位置 / 大小

`--hj-wall-size` 与 `--hj-wall-pos` 是**逐层对应**的列表，第 N 项配第 N 层。

### 2.3 删掉某一层

三个列表**必须等长**，所以删 URL 的同时要把对应的 size / pos / repeat 一起删：

```css
  /* 不要颗粒和网点 */
  --hj-wall:
    url("art/day-pixel.svg"),
    url("art/day-mist.svg");
  --hj-wall-size: 1600px 1000px, cover;
  --hj-wall-pos: center, center;
  --hj-wall-repeat: no-repeat, no-repeat;
```

### 2.4 只留玻璃（把背景清空）

```css
  --hj-wall: none;
  --hj-wall-color: #eef4f8;   /* 用纯色打底 */
```

---

## 3. 放自己的照片

照片不能直接丢进去当背景：太抢、边缘还会跟底色硬碰硬。先用工具烘焙
（左缘与底边淡出 + 罩色 + 轻微去饱和），它才能"溶"进晕染底，正文压上去也清楚。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\prepare-photos.ps1 `
  -Day  "D:\pics\白天.jpg" `
  -Night "D:\pics\夜里.jpg"
install.cmd
```

| 参数 | 默认 | 作用 |
| --- | --- | --- |
| `-DayVeil` / `-NightVeil` | 28 / 26 | 罩色强度（%）。想更清楚就调小，想更含蓄就调大 |
| `-DaySaturation` / `-NightSaturation` | 0.86 / 1.0 | 去饱和程度（1.0 = 不动） |
| `-FadeLeft` / `-FadeBottom` | 42 / 14 | 左缘 / 底边淡出占画面比例（%），让照片和晕染底接上 |
| `-MaxHeight` / `-Quality` | 1600 / 86 | 输出尺寸上限与 JPEG 质量 |
| `-Day` / `-Night` | — | 只给一个也行，另一个保持原样 |

产出的 `haerin-skin/art/day-photo.jpg`、`night-photo.jpg` 就是 CSS 里引用的那两个文件；
**不想要照片**时把文件删掉即可——缺文件那一层浏览器会直接不绘制，不会报错。
（`.gitignore` 已经排除这两个名字，所以自己的照片不会被误提交。）

---

## 4. 换右下角的开关

- **样式**：`haerin.css` 第 4 节，全部是 `.hj-*` 自有命名空间，怎么改都不会撞到客户端。
  颜色走 `--hj-surface` / `--hj-ink` / `--hj-accent` / `--hj-accent-soft` / `--hj-ring`，
  每个模式各一组。
- **文案与图标**：`haerin.js` 顶部

  ```js
  const LABEL = { day: "海粼 · 昼", night: "海粼 · 夜", auto: "海粼 · 跟随" };
  const SVG = { sun: "...", moon: "...", auto: "..." };   // 内联 SVG 字符串
  ```

- **不想要这个胶囊**：在 `install.ps1` 的 `$Assets` 里删掉 `haerin.js`，
  或者直接不引用它（`index.html` 里那一行 `<script src="…/haerin.js" defer>`）。
  皮肤照样生效，只是固定为「跟随客户端外观」。
- **想换快捷键**：`haerin.js` 里的 `watchKeys()`。

---

## 5. 改名 fork 成自己的皮肤

皮肤的名字出现在这些地方，全部可搜可替换（以 `haerin` 为例）：

| 位置 | 内容 |
| --- | --- |
| 目录 / 文件 | `haerin-skin/`、`haerin.css`、`haerin.js`、`haerin-boot.js` |
| HTML 标记 | `index.html` 里注入块的两个注释标记 `haerin-skin:begin/end` |
| 目录属性 | `data-haerin-skin` / `data-haerin-mode` / `data-haerin-night` |
| CSS 命名空间 | 开关用 `.hj-*` 与 `--hj-*` |
| localStorage 键 | `haerin.skin` / `haerin.mode` / `haerin.pos` |
| 安装器 | `install.ps1` 里的 `$BeginToken` / `$EndToken` / `$SkinSubPath` / `$Assets` |

朴素做法（在仓库根执行，把 `myskin` 换成你的名字）：

```powershell
# 1) 目录与文件名
Rename-Item haerin-skin myskin-skin
Get-ChildItem myskin-skin -Recurse -File | ForEach-Object {
  $_.Name -replace '^haerin', 'myskin' | ForEach-Object { Rename-Item $_.FullName $_ }
}
# 2) 文件内容里的标识符
Get-ChildItem -Recurse -File -Include *.css,*.js,*.html,*.ps1,*.md |
  ForEach-Object {
    $p = $_.FullName
    $t = [IO.File]::ReadAllText($p, (New-Object Text.UTF8Encoding($false))) -replace 'haerin', 'myskin' -replace 'hj-', 'ms-'
    [IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding($false)))
  }
```

> 改完记得**给 `install.ps1` 补回 BOM**：`[IO.File]::WriteAllText` 会用无 BOM 的 UTF-8，
> 而 Windows PowerShell 5.1 读无 BOM 的 .ps1 会按 ANSI 解析，中文注释会变乱码并报错。

---

## 6. 调试与排查

| 想知道 | 怎么做 |
| --- | --- |
| 某个 token 现在解析成什么 | 开 `preview.html`，F12 里 `getComputedStyle(document.body).getPropertyValue('--dsw-alias-link')` |
| 客户端有哪些 token / 两态映射改没改 | `tools\extract-upstream.ps1 -Check`，然后对比 `tools\map-*.css` 与 `haerin.css` 里的映射块 |
| 磨砂该挂在哪个元素上 | `tools\client-selectors.md`（结构后缀 + `data-*` 钩子清单） |
| 改了没生效 | 1) 跑过 `install.cmd` 吗 2) 客户端「重新加载界面」了吗 3) 是不是被浏览器缓存了（file:// 下重开就够了） |

常见坑：

- **`--hj-wall` / `-size` / `-pos` / `-repeat` 必须等长**，删层要一起删。
- **选择器要用后缀匹配**（`[class*="_sidebarCol"]`）。客户端的类名带哈希
  （`qNbT7G_sidebarCol`），哈希每次构建都变。
- **特异性**：皮肤的选择器形如 `html[data-haerin-skin="on"] body`，比上游的
  `body` / `body[data-ds-dark-theme]` 高，所以与注入顺序无关——但你新写的规则也要保持这个特异性，
  否则可能被上游覆盖。
- **改 `.ps1` 后补 BOM**（见上一节）。
