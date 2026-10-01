-- Drawing and 3D apps: solid, unblurred, never dimmed when unfocused (so colors
-- stay true while you look at a reference in another window).

-- Clip Studio Paint (Wine, via CSPenguin).
-- Untitled clipstudio.exe windows are real modal dialogs (sign-in / WebView2), not ghosts.
-- Do NOT add no_focus: the dialog could not be typed into and the main window,
-- which is disabled while the modal is open, would look frozen.
-- (หน้าต่างไม่มี Title ของ clipstudio.exe คือ modal dialog จริง — ห้ามใส่ no_focus)
hl.window_rule({ match = { class = "^(clipstudio\\.exe)$", title = "^()$" }, float = true, center = true })

-- All compositor effects off for the canvas window: fixes canvas stutter.
-- Both spellings are needed because class matching is case-sensitive.
for _, class in ipairs({ "^(CLIPStudioPaint\\.exe)$", "^(clipstudiopaint\\.exe)$" }) do
    hl.window_rule({ match = { class = class }, no_blur = true, no_shadow = true, no_anim = true, opaque = true, no_dim = true })
end

for _, class in ipairs({
    "^(blender|Blender)$",
    "^(blockbench|Blockbench)$",
    "^(krita|Krita)$",
    "^(aseprite|Aseprite)$",
    "^(gimp|Gimp|gimp-.*)$",
    "^(inkscape|org\\.inkscape\\.Inkscape)$",
}) do
    hl.window_rule({ match = { class = class }, opaque = true, no_blur = true, no_dim = true })
end
