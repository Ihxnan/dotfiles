pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Modules
import qs.Services

Item {
    id: root

    // PluginService 注入
    property string pluginId: "weBlurBackdrop"
    property var pluginService: null

    // 只有开启 "Use external manager" 时才启用
    readonly property bool externalWallpaperMode: {
        const prefs = SettingsData.screenPreferences?.wallpaper;
        return Array.isArray(prefs) && prefs.length === 0;
    }

    Loader {
        active: CompositorService.isNiri
                && SettingsData.blurredWallpaperLayer
                && root.externalWallpaperMode
        asynchronous: false

        sourceComponent: BlurredWallpaperBackground {
            // 关键：不再跟随 "Use external manager" 的屏幕过滤
            model: ShellLayout.realScreens
        }
    }
}
