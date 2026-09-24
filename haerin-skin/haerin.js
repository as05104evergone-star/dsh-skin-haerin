/* ----------------------------------------------------------------------------
   海粼 Haerin · DSH Skin —— 运行时（defer 加载）
   ----------------------------------------------------------------------------
   职责：
     1. 用 body[data-ds-dark-theme] 校正 auto 模式的解析结果；
     2. 注入右下角「猫耳胶囊」开关：点按切换 昼 / 夜，右键跟随客户端外观，
        Shift+点按 暂时收起皮肤，可拖动到任意角落并记住位置；
     3. 暴露 window.haerinSkin，便于脚本或控制台直接切换。

   皮肤本身完全由 CSS 承担，本文件不做任何样式注入，
   因此删掉它皮肤依然生效（只剩一个不会变色的 auto 模式）。
   ------------------------------------------------------------------------- */
(() => {
  "use strict";

  const root = document.documentElement;
  const KEYS = { skin: "haerin.skin", mode: "haerin.mode", pos: "haerin.pos" };
  const UI_ID = "haerin-dock";

  // 宿主组件偶尔会重建 <body> 内容；皮肤脚本可能在页面里存在多份（多次注入），
  // 用一个全局句柄保证只有最后一份生效。
  if (window.haerinSkin && window.haerinSkin.__installed) return;

  const storage = {
    get(key) {
      try {
        return window.localStorage.getItem(key);
      } catch {
        return null;
      }
    },
    set(key, value) {
      try {
        window.localStorage.setItem(key, value);
      } catch {
        /* 隐私模式：本次会话内依然可用，只是不持久化 */
      }
    },
  };

  const state = {
    skin: storage.get(KEYS.skin) === "off" ? "off" : "on",
    mode: ["day", "night"].includes(storage.get(KEYS.mode))
      ? storage.get(KEYS.mode)
      : "auto",
    pos: null,
  };

  try {
    const raw = storage.get(KEYS.pos);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (
        parsed &&
        typeof parsed.right === "number" &&
        typeof parsed.bottom === "number" &&
        isFinite(parsed.right) &&
        isFinite(parsed.bottom)
      ) {
        state.pos = { right: parsed.right, bottom: parsed.bottom };
      }
    }
  } catch {
    state.pos = null;
  }

  const appIsDark = () =>
    !!document.body && document.body.hasAttribute("data-ds-dark-theme");

  /** 皮肤当前实际渲染的是不是夜色（auto 模式向客户端外观看齐）。 */
  const resolvedNight = () =>
    state.mode === "night" || (state.mode === "auto" && appIsDark());

  const LABEL = { day: "海粼 · 昼", night: "海粼 · 夜", auto: "海粼 · 跟随" };
  const HINT = {
    day: "昼：奶油薄荷纸 · 点击切到夜",
    night: "夜：墨绿海面 · 点击切到昼",
    auto: "跟随：与客户端外观同步 · 点击切到昼",
  };

  /* ---------------------------------------------------------------- 状态写回 */

  const persist = () => {
    storage.set(KEYS.skin, state.skin);
    storage.set(KEYS.mode, state.mode);
  };

  /* ---------------------------------------------------------------- 应用状态 */

  function paint() {
    root.setAttribute("data-haerin-skin", state.skin);
    root.setAttribute("data-haerin-mode", state.mode);
    root.setAttribute("data-haerin-night", resolvedNight() ? "on" : "off");

    const dock = document.getElementById(UI_ID);
    if (!dock) return;
    dock.dataset.skin = state.skin;
    const pill = dock.querySelector(".hj-pill");
    if (!pill) return;
    pill.dataset.mode = state.mode;
    pill.setAttribute("title", `${HINT[state.mode]}（Shift+点击收起皮肤 · 右键跟随）`);
    const label = pill.querySelector(".hj-label");
    if (label) label.textContent = LABEL[state.mode];
  }

  /** 昼 ⇄ 夜：以「当前实际渲染的是哪一种」为基准取反。 */
  function toggleMode() {
    state.mode = resolvedNight() ? "day" : "night";
    persist();
    paint();
    toast(LABEL[state.mode]);
  }

  /** 整块皮肤开关（收起后只剩一只小猫，仍可点回来）。 */
  function toggleSkin() {
    state.skin = state.skin === "on" ? "off" : "on";
    persist();
    paint();
    toast(state.skin === "on" ? "海粼皮肤已开启" : "海粼皮肤已收起 · Shift+点击恢复");
  }

  /** 回到「跟随客户端外观」。 */
  function followApp() {
    state.mode = "auto";
    persist();
    paint();
    toast("海粼皮肤跟随客户端外观");
  }

  /* ------------------------------------------------------------------ 提示条 */

  let toastTimer = 0;

  function toast(text) {
    let node = document.querySelector(".hj-toast");
    if (!node) {
      node = document.createElement("div");
      node.className = "hj-toast";
      document.body.appendChild(node);
    }
    node.textContent = text;
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => node && node.remove(), 1800);
  }

  /* -------------------------------------------------------------------- 开关 */

  const SVG = {
    sun: '<svg class="hj-sun" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4.2"/><path d="M12 3.4v1.8M12 18.8v1.8M3.4 12h1.8M18.8 12h1.8M6 6l1.3 1.3M16.7 16.7 18 18M18 6l-1.3 1.3M7.3 16.7 6 18"/></svg>',
    moon: '<svg class="hj-moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M15.4 4.6a7.6 7.6 0 1 0 4 8.6 6 6 0 0 1-4-8.6Z"/></svg>',
    auto: '<svg class="hj-auto" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="7.2"/><path d="M12 4.8v14.4"/></svg>',
  };

  function build() {
    if (document.getElementById(UI_ID)) return;

    const dock = document.createElement("div");
    dock.id = UI_ID;
    dock.className = "hj-dock";
    dock.dataset.skin = state.skin;

    if (state.pos) {
      dock.style.right = `${state.pos.right}px`;
      dock.style.bottom = `${state.pos.bottom}px`;
    }

    const pill = document.createElement("button");
    pill.type = "button";
    pill.className = "hj-pill";
    pill.dataset.mode = state.mode;
    pill.setAttribute("aria-label", "海粼皮肤：切换昼 / 夜");
    pill.innerHTML =
      `<span class="hj-ears"><i></i><i></i></span>` +
      `<span class="hj-cat">${SVG.sun}${SVG.moon}${SVG.auto}</span>` +
      `<span class="hj-label">${LABEL[state.mode]}</span>`;

    dock.appendChild(pill);
    document.body.appendChild(dock);

    wire(dock, pill);
    paint();
  }

  function wire(dock, pill) {
    let drag = null;

    pill.addEventListener("pointerdown", (event) => {
      if (event.button !== 0) return;
      drag = {
        id: event.pointerId,
        x: event.clientX,
        y: event.clientY,
        moved: false,
        right: parseFloat(getComputedStyle(dock).right) || 16,
        bottom: parseFloat(getComputedStyle(dock).bottom) || 16,
      };
      pill.setPointerCapture?.(event.pointerId);
      event.preventDefault();
      event.stopPropagation();
    });

    pill.addEventListener("pointermove", (event) => {
      if (!drag || event.pointerId !== drag.id) return;
      const dx = event.clientX - drag.x;
      const dy = event.clientY - drag.y;
      if (!drag.moved && Math.abs(dx) + Math.abs(dy) < 5) return;
      drag.moved = true;
      dock.dataset.dragging = "on";
      dock.style.right = `${Math.max(4, drag.right - dx)}px`;
      dock.style.bottom = `${Math.max(4, drag.bottom - dy)}px`;
      event.stopPropagation();
    });

    pill.addEventListener("pointerup", (event) => {
      if (!drag || event.pointerId !== drag.id) return;
      const moved = drag.moved;
      drag = null;
      delete dock.dataset.dragging;
      event.stopPropagation();

      if (moved) {
        const right = parseFloat(dock.style.right) || 16;
        const bottom = parseFloat(dock.style.bottom) || 16;
        state.pos = { right, bottom };
        storage.set(KEYS.pos, JSON.stringify(state.pos));
        return;
      }

      if (event.shiftKey) {
        toggleSkin();
        return;
      }

      toggleMode();
    });

    // 右键：回到「跟随客户端外观」
    pill.addEventListener("contextmenu", (event) => {
      event.preventDefault();
      event.stopPropagation();
      followApp();
    });

    pill.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" && event.key !== " ") return;
      event.preventDefault();
      event.stopPropagation();
      toggleMode();
    });
  }

  /* ------------------------------------------------------------ 与宿主同步 */

  function watchAppTheme() {
    if (!document.body) return;
    const sync = () => paint();
    new MutationObserver(sync).observe(document.body, {
      attributes: true,
      attributeFilter: ["data-ds-dark-theme"],
    });
    // 宿主切换主题时也可能整块替换 body 的内容，顺手把胶囊找回来。
    new MutationObserver(() => {
      if (!document.getElementById(UI_ID) && document.body) build();
    }).observe(document.body, { childList: true });
  }

  /* ---------------------------------------------------------------- 快捷键 */

  function watchKeys() {
    window.addEventListener(
      "keydown",
      (event) => {
        if (!event.altKey || event.ctrlKey || event.metaKey) return;
        const key = (event.key || "").toLowerCase();
        if (key !== "h") return;
        event.preventDefault();
        if (event.shiftKey) toggleSkin();
        else toggleMode();
      },
      true,
    );
  }

  /* -------------------------------------------------------------------- 启动 */

  function start() {
    build();
    watchAppTheme();
    watchKeys();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }

  window.haerinSkin = {
    __installed: true,
    get state() {
      return { ...state, night: resolvedNight() };
    },
    day() {
      state.mode = "day";
      persist();
      paint();
    },
    night() {
      state.mode = "night";
      persist();
      paint();
    },
    auto: followApp,
    show() {
      state.skin = "on";
      persist();
      paint();
    },
    hide() {
      state.skin = "off";
      persist();
      paint();
    },
    toggle: toggleMode,
  };
})();
