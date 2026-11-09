import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root

    readonly property string ctlScriptPath: {
        var resolved = Qt.resolvedUrl("../scripts/cliamp-kde-ctl").toString();
        if (resolved.indexOf("file://") === 0) {
            return resolved.substring(7);
        }
        return "cliamp-kde-ctl";
    }

    property bool cliampInstalled: true
    property bool isRunning: false
    property string runMode: "stopped"
    property string playbackState: "stopped"

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

    property double lastUserActionMs: 0
    property var visBands: [0.18, 0.28, 0.42, 0.35, 0.50, 0.40, 0.30, 0.45, 0.25, 0.18]
    property double visPhase: 0.0

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

    Plasmoid.icon: Qt.resolvedUrl("../images/cliamp.svg")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Plasmoid.switchWidth: Kirigami.Units.gridUnit * 18
    Plasmoid.switchHeight: Kirigami.Units.gridUnit * 18

    Plasmoid.toolTipMainText: {
        if (!isRunning) return "cliamp (Offline)";
        if (trackTitle !== "") return trackArtist !== "" ? (trackArtist + " — " + trackTitle) : trackTitle;
        return "cliamp (" + playbackState + ")";
    }
    Plasmoid.toolTipSubText: {
        var volStr = isMuted ? "Muted" : ((volumeDb >= 0 ? "+" : "") + volumeDb.toFixed(1) + " dB");
        if (!isRunning) return "Saved Vol: " + volStr + " • Left-click to open • Middle-click to play";
        return "Mode: " + runMode + " • Vol: " + volStr + " • EQ: " + eqPreset;
    }

    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: FullRepresentation {}

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

    function refreshStatus() { runCtl("status", []); }
    function refreshDetails() { runCtl("details", []); }

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
        if (!sec || sec < 0 || !isFinite(sec)) return "0:00";
        var total = Math.floor(sec);
        var mins = Math.floor(total / 60);
        var secs = total % 60;
        return mins + ":" + (secs < 10 ? "0" + secs : secs);
    }

    function applySnapshot(data) {
        if (!data) return;
        if (data.provider !== undefined && data.playlists !== undefined && data.running === undefined) {
            loadingProviderPlaylists = false;
            browsedProviderPlaylists = data.playlists || [];
            return;
        }
        if (!data.ok) return;
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
        if (data.eq_bands && data.eq_bands.length === 10) eqBands = data.eq_bands;

        if (data.queue !== undefined) queueTracks = data.queue;
        if (data.local_playlists !== undefined) localPlaylists = data.local_playlists;
        if (data.providers !== undefined) providersList = data.providers;
    }

    PlasmaCore.DataSource {
        id: execEngine
        engine: "executable"
        connectedSources: []
        onNewData: {
            var stdout = data["stdout"] || "";
            execEngine.disconnectSource(sourceName);
            if (stdout.trim().length > 0) {
                try {
                    root.applySnapshot(JSON.parse(stdout.trim()));
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 95
        running: root.isRunning && root.playbackState === "playing"
        repeat: true
        onTriggered: {
            root.visPhase += 0.45;
            var nextBands = [];
            for (var i = 0; i < 10; i++) {
                var wave1 = Math.sin(root.visPhase * (1.1 + i * 0.17) + i * 0.7) * 0.5 + 0.5;
                var wave2 = Math.cos(root.visPhase * (1.7 - i * 0.09) - i * 0.4) * 0.5 + 0.5;
                nextBands.push(Math.min(0.95, Math.max(0.15, wave1 * 0.55 + wave2 * 0.45)));
            }
            root.visBands = nextBands;
        }
    }

    Timer {
        interval: Math.max(500, plasmoid.configuration.pollInterval || 1000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (plasmoid.expanded) root.refreshDetails();
            else root.refreshStatus();
        }
    }

    Component.onCompleted: {
        plasmoid.setAction("toggle", "Play / Pause", "media-playback-start");
        plasmoid.setAction("mute", "Mute / Unmute", "audio-volume-muted");
        plasmoid.setAction("next", "Next Track", "media-skip-forward");
        plasmoid.setAction("prev", "Previous Track", "media-skip-backward");
        plasmoid.setAction("daemon", "Start / Stop Background Daemon", "system-run");
        plasmoid.setAction("terminal", "Open cliamp in Terminal (TUI)", "utilities-terminal");
        plasmoid.setAction("setup", "Configure Remote Providers (cliamp setup)", "configure");
    }

    function action_toggle() { root.runCtl("toggle", []); }
    function action_mute() { root.toggleMute(); }
    function action_next() { root.runCtl("next", []); }
    function action_prev() { root.runCtl("prev", []); }
    function action_daemon() { root.runCtl("toggle-daemon", []); }
    function action_terminal() { root.runCtl("open-terminal", [plasmoid.configuration.preferredTerminal || "auto"]); }
    function action_setup() { root.runCtl("open-setup", [plasmoid.configuration.preferredTerminal || "auto"]); }
}
