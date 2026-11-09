import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 18
    switchHeight: Kirigami.Units.gridUnit * 18

    // Locate bundled cliamp-kde-ctl script inside the plasmoid package
    readonly property string ctlScriptPath: {
        var resolved = Qt.resolvedUrl("../scripts/cliamp-kde-ctl").toString();
        if (resolved.indexOf("file://") === 0) {
            return resolved.substring(7);
        }
        return "cliamp-kde-ctl";
    }

    // Core Player State Properties
    property bool cliampInstalled: true
    property bool isRunning: false
    property string runMode: "stopped" // "daemon", "tui", "stopped"
    property string playbackState: "stopped" // "playing", "paused", "stopped"

    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string trackPath: ""
    property bool isStream: false

    property string activePlaylist: ""
    property int trackIndex: -1
    property int trackTotal: 0

    property double positionSec: 0
    property double durationSec: 0
    property bool isSeekable: false
    property double volumeDb: 0.0
    property double preMuteVolumeDb: 0.0
    property bool isMuted: false

    property bool isShuffle: false
    property string repeatMode: "Off"
    property bool isMono: false
    property double playbackSpeed: 1.0

    property string eqPreset: "Flat"
    property var eqBands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Timestamp guard to prevent in-flight background polls from overwriting optimistic UI interactions
    property double lastUserActionMs: 0

    // Live Visualizer State (10 frequency bands in 0.0 .. 1.0 range)
    property var visBands: [0.18, 0.28, 0.42, 0.35, 0.50, 0.40, 0.30, 0.45, 0.25, 0.18]
    property double visPhase: 0.0
    property bool visInFlight: false

    // Extended Lists for FullRepresentation Popup
    property var queueTracks: []
    property var localPlaylists: []
    property var providersList: []
    property var browsedProviderPlaylists: []
    property string browsedProviderKey: ""
    property string browsedProviderName: ""
    property bool loadingProviderPlaylists: false

    property var eqPresetsList: [
        "Flat", "Rock", "Pop", "Jazz", "Classical", "Bass Boost",
        "Treble Boost", "Electronic", "Vocal", "Acoustic",
        "Late Night", "Hip-Hop", "R&B", "Loudness", "Custom"
    ]

    readonly property bool inPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge,
        PlasmaCore.Types.LeftEdge
    ].includes(Plasmoid.location)

    readonly property bool isHorizontalPanel: inPanel && Plasmoid.formFactor === PlasmaCore.Types.Horizontal

    // Formatted track label shown directly in the KDE Taskbar
    readonly property string panelDisplayText: {
        if (!isRunning) {
            return "cliamp";
        }
        if (trackTitle !== "") {
            return trackArtist !== "" ? (trackArtist + " – " + trackTitle) : trackTitle;
        }
        if (activePlaylist !== "") {
            return activePlaylist;
        }
        return playbackState === "playing" ? "Playing…" : (playbackState === "paused" ? "Paused" : "cliamp");
    }

    TextMetrics {
        id: panelTextMetrics
        font: Kirigami.Theme.smallFont
        text: root.panelDisplayText
    }

    // Show mini visualizer & track title in horizontal taskbar panel
    readonly property bool showPanelVis: isHorizontalPanel
    readonly property bool showPanelTrack: isHorizontalPanel && (Plasmoid.configuration.showTrackInPanel !== false) && panelDisplayText !== ""
    readonly property bool showPanelButtons: isHorizontalPanel && Boolean(Plasmoid.configuration.showPanelControls) && isRunning

    readonly property int panelAllocatedWidth: {
        var iconW = height > 0 ? Math.min(height, 28) : Kirigami.Units.iconSizes.smallMedium;
        if (!isHorizontalPanel) {
            return iconW;
        }
        var totalW = iconW + 6;
        if (showPanelVis) {
            totalW += 26;
        }
        if (showPanelTrack) {
            var maxLabelW = Math.max(60, Plasmoid.configuration.panelTrackMaxWidth || 180);
            var measuredW = Math.max(46, Math.min(maxLabelW, Math.ceil(panelTextMetrics.width) + 12));
            totalW += measuredW + 6;
        }
        if (showPanelButtons) {
            totalW += 72;
        }
        return totalW;
    }

    // Set Layout width directly on PlasmoidItem so the KDE Panel GridLayout reserves the exact width without overlapping neighbors
    Layout.minimumWidth: isHorizontalPanel ? panelAllocatedWidth : -1
    Layout.preferredWidth: isHorizontalPanel ? panelAllocatedWidth : -1
    Layout.maximumWidth: isHorizontalPanel ? panelAllocatedWidth : -1

    Plasmoid.icon: Qt.resolvedUrl("../images/cliamp.svg")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    toolTipMainText: {
        if (!isRunning) {
            return "cliamp (Offline)";
        }
        if (trackTitle !== "") {
            return trackArtist !== "" ? (trackArtist + " — " + trackTitle) : trackTitle;
        }
        return "cliamp (" + (playbackState === "playing" ? "Playing" : (playbackState === "paused" ? "Paused" : "Ready")) + ")";
    }

    toolTipSubText: {
        var volStr = isMuted
            ? ("Muted (was " + (preMuteVolumeDb >= 0 ? "+" : "") + preMuteVolumeDb.toFixed(1) + " dB)")
            : ((volumeDb >= 0 ? "+" : "") + volumeDb.toFixed(1) + " dB");
        if (!isRunning) {
            return "Saved Vol: " + volStr + " • Left-click to open • Middle-click to play";
        }
        var parts = [];
        parts.push("Mode: " + (runMode === "daemon" ? "Daemon" : "Terminal TUI"));
        if (activePlaylist !== "") {
            parts.push("Source: " + activePlaylist);
        }
        parts.push("Vol: " + volStr);
        parts.push("EQ: " + eqPreset);
        return parts.join(" • ");
    }

    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function buildCmd(subcmd, args) {
        var cmd = "python3 " + shellQuote(ctlScriptPath) + " " + subcmd;
        if (args && args.length > 0) {
            for (var i = 0; i < args.length; i++) {
                cmd += " " + shellQuote(args[i]);
            }
        }
        return cmd;
    }

    function runCtl(subcmd, args) {
        var cmd = buildCmd(subcmd, args || []);
        execEngine.connectSource(cmd);
    }

    // Optimistic UI Action Helpers
    function setVolume(dbVal) {
        var clamped = Math.max(-30.0, Math.min(6.0, Math.round(Number(dbVal) * 2) / 2.0));
        lastUserActionMs = Date.now();
        volumeDb = clamped;
        if (clamped > -29.5) {
            isMuted = false;
            preMuteVolumeDb = clamped;
        } else {
            isMuted = true;
        }
        runCtl("volume", [String(clamped.toFixed(1))]);
    }

    function stepVolume(deltaDb) {
        var base = isMuted ? preMuteVolumeDb : volumeDb;
        setVolume(base + Number(deltaDb));
    }

    function toggleMute() {
        lastUserActionMs = Date.now();
        if (isMuted || volumeDb <= -29.5) {
            var restore = (preMuteVolumeDb <= -29.5) ? 0.0 : preMuteVolumeDb;
            isMuted = false;
            volumeDb = restore;
        } else {
            preMuteVolumeDb = volumeDb;
            isMuted = true;
            volumeDb = -30.0;
        }
        runCtl("toggle-mute", []);
    }

    function refreshStatus() {
        runCtl("status", []);
    }

    function refreshDetails() {
        runCtl("details", []);
    }

    function browseProvider(providerKey, providerName) {
        browsedProviderKey = providerKey;
        browsedProviderName = providerName || providerKey;
        browsedProviderPlaylists = [];
        loadingProviderPlaylists = true;
        runCtl("provider-playlists", [providerKey]);
    }

    function closeProviderBrowser() {
        browsedProviderKey = "";
        browsedProviderName = "";
        browsedProviderPlaylists = [];
        loadingProviderPlaylists = false;
    }

    function formatTime(sec) {
        if (!sec || sec < 0 || !isFinite(sec)) {
            return "0:00";
        }
        var total = Math.floor(sec);
        var mins = Math.floor(total / 60);
        var secs = total % 60;
        return mins + ":" + (secs < 10 ? "0" + secs : secs);
    }

    function applySnapshot(data) {
        if (!data) {
            return;
        }
        if (data.provider !== undefined && data.playlists !== undefined && data.running === undefined) {
            loadingProviderPlaylists = false;
            browsedProviderPlaylists = data.playlists || [];
            return;
        }
        if (!data.ok) {
            return;
        }

        cliampInstalled = data.installed !== undefined ? Boolean(data.installed) : true;
        isRunning = Boolean(data.running);
        runMode = data.mode || "stopped";
        playbackState = data.state || "stopped";

        var tr = data.track || {};
        trackTitle = tr.title || "";
        trackArtist = tr.artist || "";
        trackAlbum = tr.album || "";
        trackPath = tr.path || "";
        isStream = Boolean(tr.stream);

        activePlaylist = data.playlist || "";
        trackIndex = data.index !== undefined ? Number(data.index) : -1;
        trackTotal = data.total !== undefined ? Number(data.total) : 0;

        positionSec = data.position !== undefined ? Number(data.position) : 0;
        durationSec = data.duration !== undefined ? Number(data.duration) : 0;
        isSeekable = Boolean(data.seekable);

        var recentUserChange = (Date.now() - lastUserActionMs) < 1200;
        if (!recentUserChange) {
            volumeDb = data.volume !== undefined ? Number(data.volume) : volumeDb;
            isMuted = data.muted !== undefined ? Boolean(data.muted) : (volumeDb <= -29.5);
            if (data.pre_mute_volume !== undefined) {
                preMuteVolumeDb = Number(data.pre_mute_volume);
            } else if (!isMuted) {
                preMuteVolumeDb = volumeDb;
            }
        }

        isShuffle = Boolean(data.shuffle);
        repeatMode = data.repeat || "Off";
        isMono = Boolean(data.mono);
        playbackSpeed = data.speed !== undefined ? Number(data.speed) : 1.0;

        eqPreset = data.eq_preset || "Flat";
        if (data.eq_bands && data.eq_bands.length === 10) {
            eqBands = data.eq_bands;
        }

        if (data.queue !== undefined) {
            queueTracks = data.queue;
        }
        if (data.local_playlists !== undefined) {
            localPlaylists = data.local_playlists;
        }
        if (data.providers !== undefined) {
            providersList = data.providers;
        }

        if (!isRunning || playbackState !== "playing") {
            visBands = [0.18, 0.30, 0.45, 0.35, 0.55, 0.40, 0.28, 0.48, 0.32, 0.20];
        }
    }

    Plasma5Support.DataSource {
        id: execEngine
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || "";
            execEngine.disconnectSource(sourceName);
            if (stdout.trim().length > 0) {
                try {
                    var parsed = JSON.parse(stdout.trim());
                    root.applySnapshot(parsed);
                } catch (e) {
                    // Ignore malformed output
                }
            }
        }
    }

    // Dedicated Visualizer Frame Engine
    Plasma5Support.DataSource {
        id: visEngine
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || "";
            visEngine.disconnectSource(sourceName);
            root.visInFlight = false;
            if (stdout.trim().length > 0) {
                try {
                    var lines = stdout.trim().split("\n");
                    var parsed = JSON.parse(lines[lines.length - 1]);
                    if (parsed && parsed.bands && parsed.bands.length === 10) {
                        var hasNonZero = false;
                        for (var i = 0; i < 10; i++) {
                            if (Number(parsed.bands[i]) > 0.01) {
                                hasNonZero = true;
                                break;
                            }
                        }
                        if (hasNonZero) {
                            var scaled = [];
                            for (var j = 0; j < 10; j++) {
                                scaled.push(Math.min(1.0, Math.max(0.05, Number(parsed.bands[j]) * 1.4)));
                            }
                            root.visBands = scaled;
                            return;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // Live Visualizer Animation & Stream Polling Timer
    Timer {
        id: visTimer
        interval: 90
        running: root.isRunning && root.playbackState === "playing"
        repeat: true
        onTriggered: {
            root.visPhase += 0.45;
            if (!root.visInFlight) {
                root.visInFlight = true;
                visEngine.connectSource("cliamp visstream --fps 60 | head -n 1");
            }
            // Smooth fallback/harmonic motion when visstream returns zeros or between IPC frames
            var nextBands = [];
            for (var i = 0; i < 10; i++) {
                var eqBoost = (root.eqBands && root.eqBands.length > i) ? (Number(root.eqBands[i]) + 12) / 24.0 : 0.5;
                var wave1 = Math.sin(root.visPhase * (1.1 + i * 0.17) + i * 0.7) * 0.5 + 0.5;
                var wave2 = Math.cos(root.visPhase * (1.7 - i * 0.09) - i * 0.4) * 0.5 + 0.5;
                var synth = Math.min(0.95, Math.max(0.12, (wave1 * 0.55 + wave2 * 0.45) * (0.55 + eqBoost * 0.55)));
                var prev = (root.visBands && root.visBands.length > i) ? Number(root.visBands[i]) : 0.2;
                nextBands.push(prev * 0.4 + synth * 0.6);
            }
            root.visBands = nextBands;
        }
    }

    Timer {
        id: pollTimer
        interval: Math.max(500, Plasmoid.configuration.pollInterval || 1000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.expanded) {
                root.refreshDetails();
            } else {
                root.refreshStatus();
            }
        }
    }

    onExpandedChanged: {
        if (expanded) {
            refreshDetails();
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.playbackState === "playing" ? "Pause" : "Play"
            icon.name: root.playbackState === "playing" ? "media-playback-pause" : "media-playback-start"
            onTriggered: root.runCtl("toggle", [])
        },
        PlasmaCore.Action {
            text: root.isMuted ? "Unmute Audio" : "Mute Audio"
            icon.name: root.isMuted ? "audio-volume-muted" : "audio-volume-high"
            onTriggered: root.toggleMute()
        },
        PlasmaCore.Action {
            text: "Next Track"
            icon.name: "media-skip-forward"
            enabled: root.isRunning
            onTriggered: root.runCtl("next", [])
        },
        PlasmaCore.Action {
            text: "Previous Track"
            icon.name: "media-skip-backward"
            enabled: root.isRunning
            onTriggered: root.runCtl("prev", [])
        },
        PlasmaCore.Action {
            text: "Stop"
            icon.name: "media-playback-stop"
            enabled: root.isRunning
            onTriggered: root.runCtl("stop", [])
        },
        PlasmaCore.Action {
            isSeparator: true
        },
        PlasmaCore.Action {
            text: root.isRunning ? "Stop Background Daemon" : "Start Background Daemon"
            icon.name: root.isRunning ? "process-stop" : "system-run"
            onTriggered: root.runCtl("toggle-daemon", [])
        },
        PlasmaCore.Action {
            text: "Open cliamp in Terminal (TUI)"
            icon.name: "utilities-terminal"
            onTriggered: root.runCtl("open-terminal", [Plasmoid.configuration.preferredTerminal || "auto"])
        },
        PlasmaCore.Action {
            text: "Configure Remote Providers (cliamp setup)"
            icon.name: "configure"
            onTriggered: root.runCtl("open-setup", [Plasmoid.configuration.preferredTerminal || "auto"])
        }
    ]
}
