#!/bin/bash
swaymsg client.focused            "{{colors.primary.default.hex}} {{colors.surface.default.hex}} {{colors.on_surface.default.hex}} {{colors.primary.default.hex}} {{colors.primary.default.hex}}"
swaymsg client.focused_inactive   "{{colors.outline.default.hex}} {{colors.surface.default.hex}} {{colors.on_surface_variant.default.hex}} {{colors.outline.default.hex}} {{colors.outline.default.hex}}"
swaymsg client.unfocused          "{{colors.surface_container.default.hex}} {{colors.surface.default.hex}} {{colors.on_surface_variant.default.hex}} {{colors.surface_container.default.hex}} {{colors.surface_container.default.hex}}"
swaymsg client.urgent             "{{colors.error.default.hex}} {{colors.surface.default.hex}} {{colors.on_surface.default.hex}} {{colors.error.default.hex}} {{colors.error.default.hex}}"
swaymsg client.placeholder        "{{colors.surface_container.default.hex}} {{colors.surface.default.hex}} {{colors.on_surface_variant.default.hex}} {{colors.surface_container.default.hex}} {{colors.surface_container.default.hex}}"
swaymsg client.background         "{{colors.surface.default.hex}}"
