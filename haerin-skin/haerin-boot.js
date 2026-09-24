/* ----------------------------------------------------------------------------
   海粼 Haerin · DSH Skin —— 首帧引导（同步，必须放在 <head>）
   ----------------------------------------------------------------------------
   在浏览器绘制任何像素之前把皮肤状态写到 <html> 上，因此：
     · 刷新后不会先闪一下默认黑白配色；
     · CSS 选择器只需读取 html[data-haerin-*] 与 body[data-ds-dark-theme]。

   持久化的键（localStorage，命名空间 haerin.*）：
     haerin.skin  "on" | "off"          默认 on
     haerin.mode  "auto" | "day" | "night"   默认 auto（跟随客户端外观）
   ------------------------------------------------------------------------- */
(() => {
  const root = document.documentElement;

  const read = (key, fallback) => {
    try {
      const value = window.localStorage.getItem(key);
      return value === null ? fallback : value;
    } catch {
      return fallback;
    }
  };

  const skin = read("haerin.skin", "on") === "off" ? "off" : "on";
  const stored = read("haerin.mode", "auto");
  const mode = stored === "day" || stored === "night" ? stored : "auto";

  // auto 模式下先按系统偏好给一个临时值；haerin.js 会用 body[data-ds-dark-theme] 纠正。
  let night = mode === "night";
  if (mode === "auto") {
    try {
      night = window.matchMedia("(prefers-color-scheme: dark)").matches;
    } catch {
      night = false;
    }
  }

  root.setAttribute("data-haerin-skin", skin);
  root.setAttribute("data-haerin-mode", mode);
  root.setAttribute("data-haerin-night", night ? "on" : "off");
})();
