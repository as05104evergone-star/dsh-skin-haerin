# art/ —— 背景素材

这些文件被 `haerin.css` 的 `--hj-wall` 逐层引用（顺序＝自上而下）。
全部是手写 SVG，直接编辑即可；换成别的文件名时记得同步改 `--hj-wall` / `-size` / `-pos` / `-repeat`
三个列表（**必须等长**）。

| 文件 | 层 | 说明 |
| --- | --- | --- |
| `grain.svg` | 颗粒 | `feTurbulence` 噪点，180px 无缝平铺，透明度 4.5% |
| `day-pixel.svg` | 像素贴纸 | 8-bit 雪片 / 丹宁提花 / 腮红心 / 兔子；1600×1000 定尺寸 |
| `night-pixel.svg` | 像素贴纸 | 8-bit 胭脂红花 / 骨白星 / 月牙 / 红猫；1600×1000 定尺寸 |
| `dither-day.svg` | 抖动网点 | 4px 棋盘格，冷蓝 5% |
| `dither-night.svg` | 抖动网点 | 4px 棋盘格，骨白 4.5% |
| `day-mist.svg` | 晕染底 | 雪蓝天光 → 雪面近白；右侧用 `<mask>` 淡出让位给照片 |
| `night-mist.svg` | 晕染底 | 近黑墨底 + 冷蓝 + 右下暖红；同样右侧淡出 |
| `day-photo.jpg` | 照片 | 仓库附带（非 MIT，见 [许可说明](../../README.md#许可与声明)） |
| `night-photo.jpg` | 照片 | 同上 |

## 像素贴纸怎么写

`day-pixel.svg` / `night-pixel.svg` 里，每个图形先在 `<defs>` 里用
`<g fill="currentColor" id="…">` 定义成**整数网格上的方块集合**：

```svg
<g fill="currentColor" id="heart">
  <rect x="1" y="0" width="2" height="1" />
  <rect x="4" y="0" width="2" height="1" />
  <rect x="0" y="1" width="7" height="2" />
  …
</g>
```

放置时用**整数倍**放大，靠父级 `<g>` 的 `color` 上色：

```svg
<g color="#4a6c9c" opacity="0.58">
  <g transform="translate(1124,764) scale(6)"><use href="#flower" /></g>
</g>
```

两个要点：

1. `shape-rendering="crispEdges"` 写在最外层 `<g>` 上，边缘才是硬方块；
2. `scale()` 用整数（3/5/6/7…），用小数会让像素块半格、糊掉。

想加自己的图形：照着上面的 sprite 写一个 `id`，再 `use` 出去即可。
注意画布是 `1600×1000` 且**居中不缩放**，所以在 1440 宽的窗口里，
SVG 坐标 `x` 会落在屏幕 `x-80` 的位置——太靠左的图形会被切掉，
左下角的兔子/猫就是为此往右挪过的。

## 照片

用 `tools/prepare-photos.ps1` 生成，别直接丢原图：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\tools\prepare-photos.ps1 `
  -Day "D:\pics\白天.jpg" -Night "D:\pics\夜里.jpg"
```

参数说明见 [docs/CUSTOMIZE.md](../../docs/CUSTOMIZE.md#3-放自己的照片)。
删掉照片文件也可以——`--hj-wall` 里那一层会静默不绘制，剩下晕染底 + 像素 + 网点。
