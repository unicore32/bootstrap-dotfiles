-- Shared terminal behavior for macOS and Windows.
--
-- The leader key deliberately differs from tmux/Herdr's Ctrl+B so nested
-- sessions remain usable: Ctrl+G controls WezTerm; Ctrl+B controls tmux/Herdr.
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = 'Tokyo Night'
config.window_decorations = 'RESIZE'
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 100000
config.window_padding = {
  left = 8,
  right = 8,
  top = 6,
  bottom = 6,
}

-- Match rendered characters rather than US-keyboard positions. This keeps the
-- leader + | split binding intuitive on Japanese keyboard layouts.
config.key_map_preference = 'Mapped'
config.leader = {
  key = 'g',
  mods = 'CTRL',
  timeout_milliseconds = 1500,
}

config.keys = {
  -- Pressing the leader twice sends Ctrl+G through to the terminal program.
  {
    key = 'g',
    mods = 'LEADER|CTRL',
    action = act.SendKey { key = 'g', mods = 'CTRL' },
  },
  {
    key = '|',
    mods = 'LEADER|SHIFT',
    action = act.SplitPane {
      direction = 'Right',
      command = { domain = 'CurrentPaneDomain' },
    },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = act.SplitPane {
      direction = 'Down',
      command = { domain = 'CurrentPaneDomain' },
    },
  },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
  { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },
  {
    key = 'o',
    mods = 'LEADER',
    action = act.ShowLauncherArgs {
      flags = 'FUZZY|TABS|DOMAINS|LAUNCH_MENU_ITEMS',
    },
  },
}

if wezterm.target_triple:find('windows') then
  -- WezTerm discovers WSL distributions from `wsl -l -v`. Prefer Ubuntu (the
  -- distro this bootstrap documents) and otherwise use the first installed one.
  local wsl_domains = wezterm.default_wsl_domains()
  local default_wsl_domain = wsl_domains[1]

  for _, domain in ipairs(wsl_domains) do
    if domain.distribution == 'Ubuntu' then
      default_wsl_domain = domain
      break
    end
  end

  if default_wsl_domain then
    -- Bootstrap installs zsh but intentionally does not change WSL's login
    -- shell. WezTerm starts zsh directly without changing system ownership.
    default_wsl_domain.default_prog = { 'zsh', '-l' }
    config.wsl_domains = wsl_domains
    config.default_domain = default_wsl_domain.name
  end

  config.launch_menu = {
    { label = 'PowerShell 7', args = { 'pwsh.exe', '-NoLogo' } },
    { label = 'Command Prompt', args = { 'cmd.exe' } },
  }

  table.insert(config.keys, {
    key = 'p',
    mods = 'LEADER',
    action = act.SpawnCommandInNewTab { args = { 'pwsh.exe', '-NoLogo' } },
  })
  table.insert(config.keys, {
    key = 'm',
    mods = 'LEADER',
    action = act.SpawnCommandInNewTab { args = { 'cmd.exe' } },
  })
end

return config
