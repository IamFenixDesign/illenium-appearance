(function () {
  const resourceName =
    typeof GetParentResourceName === "function"
      ? GetParentResourceName()
      : "illenium-appearance";

  const STORAGE_KEY = "fenix-appearance-colors";

  const COLOR_OPTIONS = [
    { key: "accent", css: "--fenix-accent", def: "#7c6cf0" },
    { key: "accentSoft", css: "--fenix-accent-soft", def: "#2a2840" },
    { key: "accentText", css: "--fenix-accent-text", def: "#ddd6fe" },
    { key: "surface", css: "--fenix-surface", def: "#1c1c24" },
    { key: "field", css: "--fenix-field", def: "#18181f" },
    { key: "fieldHover", css: "--fenix-field-hover", def: "#22222c" },
    { key: "border", css: "--fenix-border", def: "#32323e" },
    { key: "text", css: "--fenix-text", def: "#f2f2f6" },
    { key: "muted", css: "--fenix-muted", def: "#9494a8" },
    { key: "ok", css: "--fenix-ok", def: "#22c55e" },
    { key: "okBg", css: "--fenix-ok-bg", def: "#15251a" },
    { key: "okBorder", css: "--fenix-ok-border", def: "#2a5a38" },
    { key: "danger", css: "--fenix-danger", def: "#ef4444" },
    { key: "dangerBg", css: "--fenix-danger-bg", def: "#2a1818" },
    { key: "dangerBorder", css: "--fenix-danger-border", def: "#5c2828" },
  ];

  const DEFAULT_SETTINGS_LOCALE = {
    title: "Colors",
    subtitle: "Live preview",
    toggle: "Colors",
    save: "Save",
    saved: "Saved",
    reset: "Reset",
    preview: "Preview · unsaved",
    savedStatus: "Colors saved",
    defaultsStatus: "Defaults · unsaved",
    colors: {
      accent: "Accent",
      accentSoft: "Soft accent",
      accentText: "Accent text",
      surface: "Surface",
      field: "Fields",
      fieldHover: "Fields hover",
      border: "Borders",
      text: "Text",
      muted: "Secondary text",
      ok: "Save",
      okBg: "Save background",
      okBorder: "Save border",
      danger: "Exit",
      dangerBg: "Exit background",
      dangerBorder: "Exit border",
    },
    camera: {
      reset: "Reset camera",
      move: "Move camera",
      hint: "Drag · Scroll zoom · Alt height · Enter confirm",
    },
  };

  let settingsLocale = DEFAULT_SETTINGS_LOCALE;

  function mergeSettingsLocale(raw) {
    const src = (raw && raw.settings) || {};
    return {
      title: src.title || DEFAULT_SETTINGS_LOCALE.title,
      subtitle: src.subtitle || DEFAULT_SETTINGS_LOCALE.subtitle,
      toggle: src.toggle || DEFAULT_SETTINGS_LOCALE.toggle,
      save: src.save || DEFAULT_SETTINGS_LOCALE.save,
      saved: src.saved || DEFAULT_SETTINGS_LOCALE.saved,
      reset: src.reset || DEFAULT_SETTINGS_LOCALE.reset,
      preview: src.preview || DEFAULT_SETTINGS_LOCALE.preview,
      savedStatus: src.savedStatus || DEFAULT_SETTINGS_LOCALE.savedStatus,
      defaultsStatus: src.defaultsStatus || DEFAULT_SETTINGS_LOCALE.defaultsStatus,
      colors: Object.assign({}, DEFAULT_SETTINGS_LOCALE.colors, src.colors || {}),
      camera: Object.assign({}, DEFAULT_SETTINGS_LOCALE.camera, src.camera || {}),
    };
  }

  function colorLabel(key) {
    return (settingsLocale.colors && settingsLocale.colors[key]) || key;
  }

  function post(eventName, data) {
    return fetch(`https://${resourceName}/${eventName}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data ?? {}),
    }).catch(function () {});
  }

  function fetchLocales() {
    return fetch(`https://${resourceName}/appearance_get_locales`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: "{}",
    })
      .then(function (res) {
        return res.json();
      })
      .then(function (data) {
        settingsLocale = mergeSettingsLocale(data);
        applySettingsLocale();
        return settingsLocale;
      })
      .catch(function () {
        settingsLocale = DEFAULT_SETTINGS_LOCALE;
        applySettingsLocale();
        return settingsLocale;
      });
  }

  const ICONS = {
    move:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="5 9 2 12 5 15"/><polyline points="9 5 12 2 15 5"/><polyline points="15 19 12 22 9 19"/><polyline points="19 9 22 12 19 15"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="12" y1="2" x2="12" y2="22"/></svg>',
    reset:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>',
    settings:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>',
  };

  let zone = null;
  let dock = null;
  let toggleBtn = null;
  let resetBtn = null;
  let settingsBtn = null;
  let settingsPanel = null;
  let resetColorsBtn = null;
  let settingsTitleEl = null;
  let settingsSubtitleEl = null;
  let saveBtn = null;
  let statusEl = null;
  let uiOpen = false;
  let moveMode = false;
  let settingsOpen = false;
  let dirty = false;
  let dragging = false;
  let lastX = 0;
  let lastY = 0;

  let savedColors = loadColors();
  let draftColors = cloneColors(savedColors);

  function defaultColors() {
    const out = {};
    COLOR_OPTIONS.forEach(function (opt) {
      out[opt.key] = opt.def;
    });
    return out;
  }

  function cloneColors(src) {
    return Object.assign({}, src);
  }

  function loadColors() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return defaultColors();
      return Object.assign(defaultColors(), JSON.parse(raw));
    } catch (e) {
      return defaultColors();
    }
  }

  function hexToRgb(hex) {
    let h = String(hex || "").replace("#", "");
    if (h.length === 3) {
      h = h
        .split("")
        .map(function (c) {
          return c + c;
        })
        .join("");
    }
    const n = parseInt(h, 16);
    if (Number.isNaN(n)) return "255, 255, 255";
    return ((n >> 16) & 255) + ", " + ((n >> 8) & 255) + ", " + (n & 255);
  }

  function colorsToThemePatch(map) {
    return {
      primaryBackground: hexToRgb(map.accent),
      primaryBackgroundSelected: hexToRgb(map.accent),
      secondaryBackground: hexToRgb(map.surface),
      fontColor: hexToRgb(map.text),
      fontColorHover: hexToRgb(map.text),
      fontColorSelected: hexToRgb(map.accentText),
      smoothBackgroundTransition: true,
    };
  }

  function persistColors(map) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(map));
    } catch (e) {}
  }

  function applyColors(map) {
    const root = document.documentElement;
    COLOR_OPTIONS.forEach(function (opt) {
      root.style.setProperty(opt.css, map[opt.key] || opt.def);
    });
    root.style.setProperty("--fenix-accent-strong", map.accent || "#6b5ce0");
    root.style.setProperty("--fenix-surface-strong", map.fieldHover || "#24242e");
    window.dispatchEvent(
      new CustomEvent("fenix-colors-update", {
        detail: colorsToThemePatch(map),
      })
    );
  }

  window.__fenixGetThemePatch = function () {
    return colorsToThemePatch(savedColors);
  };

  function setDirty(value) {
    dirty = !!value;
    if (saveBtn) {
      saveBtn.disabled = !dirty;
      saveBtn.classList.toggle("is-disabled", !dirty);
      if (dirty) {
        saveBtn.textContent = settingsLocale.save;
        saveBtn.classList.remove("is-saved");
      }
    }
    if (settingsPanel) settingsPanel.classList.toggle("is-dirty", dirty);
  }

  function setStatus(text, kind) {
    if (!statusEl) return;
    statusEl.textContent = text || "";
    statusEl.dataset.kind = kind || "";
  }

  function syncInputsFromDraft() {
    if (!settingsPanel) return;
    settingsPanel.querySelectorAll('input[type="color"]').forEach(function (input) {
      const key = input.dataset.key;
      input.value = draftColors[key];
      const hexEl = settingsPanel.querySelector('.fenix-settings-hex[data-key="' + key + '"]');
      if (hexEl) hexEl.textContent = draftColors[key];
    });
  }

  function previewDraft() {
    applyColors(draftColors);
    setDirty(JSON.stringify(draftColors) !== JSON.stringify(savedColors));
    setStatus(dirty ? settingsLocale.preview : "", dirty ? "preview" : "");
  }

  function saveDraft() {
    savedColors = cloneColors(draftColors);
    persistColors(savedColors);
    applyColors(savedColors);
    setDirty(false);
    if (saveBtn) {
      saveBtn.textContent = settingsLocale.saved;
      saveBtn.classList.add("is-saved");
    }
    setStatus(settingsLocale.savedStatus, "saved");
    setTimeout(function () {
      if (!dirty) setStatus("", "");
    }, 1600);
  }

  function makeDockBtn(id, title, icon, className) {
    const btn = document.createElement("button");
    btn.id = id;
    btn.type = "button";
    btn.title = title;
    btn.setAttribute("aria-label", title);
    btn.className = "fenix-dock-btn" + (className ? " " + className : "");
    btn.innerHTML = icon;
    return btn;
  }

  function setBtnLabel(btn, title) {
    if (!btn) return;
    btn.title = title;
    btn.setAttribute("aria-label", title);
  }

  function applySettingsLocale() {
    if (settingsTitleEl) settingsTitleEl.textContent = settingsLocale.title;
    if (settingsSubtitleEl) settingsSubtitleEl.textContent = settingsLocale.subtitle;
    if (resetColorsBtn) resetColorsBtn.textContent = settingsLocale.reset;
    if (saveBtn) {
      saveBtn.textContent = saveBtn.classList.contains("is-saved")
        ? settingsLocale.saved
        : settingsLocale.save;
    }
    if (settingsPanel) {
      settingsPanel.querySelectorAll(".fenix-settings-label[data-key]").forEach(function (el) {
        el.textContent = colorLabel(el.dataset.key);
      });
    }
    setBtnLabel(resetBtn, settingsLocale.camera.reset);
    setBtnLabel(toggleBtn, settingsLocale.camera.move);
    setBtnLabel(settingsBtn, settingsLocale.toggle);
    if (zone) {
      const hint = zone.querySelector(".fenix-freecam-hint");
      if (hint) hint.textContent = settingsLocale.camera.hint;
    }
    if (dirty) setStatus(settingsLocale.preview, "preview");
  }

  function buildSettingsPanel() {
    const panel = document.createElement("div");
    panel.id = "fenix-settings-panel";
    panel.setAttribute("aria-hidden", "true");

    const header = document.createElement("div");
    header.className = "fenix-settings-header";
    settingsTitleEl = document.createElement("h3");
    settingsTitleEl.textContent = settingsLocale.title;
    settingsSubtitleEl = document.createElement("span");
    settingsSubtitleEl.textContent = settingsLocale.subtitle;
    header.appendChild(settingsTitleEl);
    header.appendChild(settingsSubtitleEl);

    statusEl = document.createElement("div");
    statusEl.className = "fenix-settings-status";

    const list = document.createElement("div");
    list.className = "fenix-settings-list";

    COLOR_OPTIONS.forEach(function (opt) {
      const row = document.createElement("label");
      row.className = "fenix-settings-row";
      row.setAttribute("for", "fenix-color-" + opt.key);

      const meta = document.createElement("div");
      meta.className = "fenix-settings-meta";

      const labelEl = document.createElement("span");
      labelEl.className = "fenix-settings-label";
      labelEl.dataset.key = opt.key;
      labelEl.textContent = colorLabel(opt.key);

      const hexEl = document.createElement("span");
      hexEl.className = "fenix-settings-hex";
      hexEl.dataset.key = opt.key;
      hexEl.textContent = draftColors[opt.key] || opt.def;

      meta.appendChild(labelEl);
      meta.appendChild(hexEl);

      const input = document.createElement("input");
      input.type = "color";
      input.id = "fenix-color-" + opt.key;
      input.value = draftColors[opt.key] || opt.def;
      input.dataset.key = opt.key;

      input.addEventListener("input", function () {
        draftColors[opt.key] = input.value;
        hexEl.textContent = input.value;
        previewDraft();
      });

      row.appendChild(meta);
      row.appendChild(input);
      list.appendChild(row);
    });

    const footer = document.createElement("div");
    footer.className = "fenix-settings-footer";

    resetColorsBtn = document.createElement("button");
    resetColorsBtn.type = "button";
    resetColorsBtn.className = "fenix-settings-reset";
    resetColorsBtn.textContent = settingsLocale.reset;
    resetColorsBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      draftColors = defaultColors();
      syncInputsFromDraft();
      previewDraft();
      setStatus(settingsLocale.defaultsStatus, "preview");
    });

    saveBtn = document.createElement("button");
    saveBtn.type = "button";
    saveBtn.className = "fenix-settings-save is-disabled";
    saveBtn.textContent = settingsLocale.save;
    saveBtn.disabled = true;
    saveBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      if (!dirty) return;
      saveDraft();
    });

    footer.appendChild(resetColorsBtn);
    footer.appendChild(saveBtn);
    panel.appendChild(header);
    panel.appendChild(statusEl);
    panel.appendChild(list);
    panel.appendChild(footer);

    panel.addEventListener("mousedown", function (event) {
      event.stopPropagation();
    });

    return panel;
  }

  function setSettingsOpen(open) {
    settingsOpen = !!open;
    ensureDock();
    if (settingsBtn) settingsBtn.classList.toggle("is-active", settingsOpen);
    if (settingsPanel) {
      settingsPanel.classList.toggle("is-open", settingsOpen);
      settingsPanel.setAttribute("aria-hidden", settingsOpen ? "false" : "true");
    }

    if (settingsOpen) {
      draftColors = cloneColors(savedColors);
      syncInputsFromDraft();
      applyColors(draftColors);
      setDirty(false);
      setStatus("", "");
      if (moveMode) setMoveMode(false);
      return;
    }

    // Al cerrar sin guardar: volver a los colores guardados
    draftColors = cloneColors(savedColors);
    applyColors(savedColors);
    setDirty(false);
    setStatus("", "");
  }

  function ensureDock() {
    if (dock) return dock;

    dock = document.createElement("div");
    dock.id = "fenix-action-dock";

    resetBtn = makeDockBtn("fenix-cam-reset", settingsLocale.camera.reset, ICONS.reset);
    toggleBtn = makeDockBtn("fenix-cam-toggle", settingsLocale.camera.move, ICONS.move);
    settingsBtn = makeDockBtn("fenix-settings-toggle", settingsLocale.toggle, ICONS.settings);
    settingsPanel = buildSettingsPanel();

    resetBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      resetCamera();
    });

    toggleBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      setMoveMode(!moveMode);
    });

    settingsBtn.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      setSettingsOpen(!settingsOpen);
    });

    dock.appendChild(resetBtn);
    dock.appendChild(toggleBtn);
    dock.appendChild(settingsBtn);
    dock.appendChild(settingsPanel);
    document.body.appendChild(dock);
    return dock;
  }

  function ensureZone() {
    if (zone) return zone;

    zone = document.createElement("div");
    zone.id = "fenix-freecam-zone";
    zone.innerHTML =
      '<div class="fenix-freecam-hint">' + settingsLocale.camera.hint + "</div>";
    document.body.appendChild(zone);

    zone.addEventListener("mousedown", function (event) {
      if (!moveMode || event.button !== 0) return;
      dragging = true;
      lastX = event.clientX;
      lastY = event.clientY;
      zone.classList.add("is-dragging");
      event.preventDefault();
    });

    window.addEventListener("mousemove", function (event) {
      if (!dragging || !moveMode) return;
      const dx = event.clientX - lastX;
      const dy = event.clientY - lastY;
      lastX = event.clientX;
      lastY = event.clientY;
      if (dx === 0 && dy === 0) return;
      post("appearance_camera_orbit", {
        dx: dx,
        dy: dy,
        alt: !!event.altKey,
      });
    });

    window.addEventListener("mouseup", function () {
      if (!dragging) return;
      dragging = false;
      if (zone) zone.classList.remove("is-dragging");
    });

    zone.addEventListener(
      "wheel",
      function (event) {
        if (!moveMode) return;
        event.preventDefault();
        post("appearance_camera_zoom", { delta: event.deltaY });
      },
      { passive: false }
    );

    zone.addEventListener("contextmenu", function (event) {
      event.preventDefault();
    });

    window.addEventListener("keydown", function (event) {
      if (!uiOpen) return;
      if (event.key === "Escape" && settingsOpen) {
        event.preventDefault();
        setSettingsOpen(false);
        return;
      }
      if (!moveMode) return;
      if (event.key !== "Enter") return;
      event.preventDefault();
      setMoveMode(false);
    });

    return zone;
  }

  function resetCamera() {
    dragging = false;
    if (zone) zone.classList.remove("is-dragging");
    post("appearance_camera_reset", {});
  }

  function setMoveMode(enabled) {
    moveMode = !!enabled;
    ensureDock();
    const el = ensureZone();

    if (toggleBtn) toggleBtn.classList.toggle("is-active", moveMode);
    el.classList.toggle("is-visible", moveMode && uiOpen);
    post("appearance_camera_freemode", { enabled: moveMode });

    if (moveMode && settingsOpen) setSettingsOpen(false);

    if (!moveMode) {
      dragging = false;
      el.classList.remove("is-dragging");
    }
  }

  function setUiOpen(open) {
    uiOpen = !!open;
    const d = ensureDock();
    d.classList.toggle("is-shown", uiOpen);

    if (!uiOpen) {
      moveMode = false;
      if (settingsOpen) {
        // descartar preview no guardado
        draftColors = cloneColors(savedColors);
        applyColors(savedColors);
      }
      settingsOpen = false;
      if (toggleBtn) toggleBtn.classList.remove("is-active");
      if (settingsBtn) settingsBtn.classList.remove("is-active");
      if (settingsPanel) {
        settingsPanel.classList.remove("is-open");
        settingsPanel.setAttribute("aria-hidden", "true");
      }
      ensureZone().classList.remove("is-visible");
      dragging = false;
      dirty = false;
      post("appearance_camera_freemode", { enabled: false });
      return;
    }

    applyColors(savedColors);
    ensureZone().classList.toggle("is-visible", moveMode);
  }

  applyColors(savedColors);

  function applyMenuPosition(position) {
    const raw = String(position || "middle").toLowerCase().trim();
    let key = "middle";
    if (raw === "top-left" || raw === "top" || raw === "topleft") key = "top-left";
    else if (raw === "bottom-left" || raw === "bottom" || raw === "bottomleft") key = "bottom-left";

    const root = document.documentElement;
    root.dataset.menuPosition = key;

    if (key === "top-left") {
      root.style.setProperty("--fenix-menu-align", "flex-start");
      root.style.setProperty("--fenix-menu-pad-top", "28px");
      root.style.setProperty("--fenix-menu-pad-bottom", "0px");
    } else if (key === "bottom-left") {
      root.style.setProperty("--fenix-menu-align", "flex-end");
      root.style.setProperty("--fenix-menu-pad-top", "0px");
      root.style.setProperty("--fenix-menu-pad-bottom", "28px");
    } else {
      root.style.setProperty("--fenix-menu-align", "center");
      root.style.setProperty("--fenix-menu-pad-top", "0px");
      root.style.setProperty("--fenix-menu-pad-bottom", "0px");
    }
  }

  window.addEventListener("message", function (event) {
    const data = event.data;
    if (!data || !data.type) return;
    if (data.type === "appearance_display") {
      const payload = data.payload || {};
      applyMenuPosition(payload.menuPosition);
      fetchLocales();
      setUiOpen(true);
    }
    if (data.type === "appearance_hide") setUiOpen(false);
  });

  fetchLocales();
})();
