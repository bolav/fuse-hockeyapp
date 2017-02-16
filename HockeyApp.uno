using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Triggers;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.Android;

using Fuse.Platform;

public class HockeyApp : Behavior {
    public HockeyApp () {
        debug_log "Constructor";
        if defined(DESIGNMODE)
            return;
        if ((Fuse.Platform.Lifecycle.State == Fuse.Platform.ApplicationState.Foreground)
            || (Fuse.Platform.Lifecycle.State == Fuse.Platform.ApplicationState.Interactive)
            ) {
            _foreground = true;
        }
        else {
            Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
        }
    }

    void OnEnteringForeground(Fuse.Platform.ApplicationState newState)
    {
        _foreground = true;
        Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
        Init();
    }

    static bool _foreground = false;
    static bool _inited = false;
    void Init() {
        debug_log "Init";
        if defined(DESIGNMODE)
            return;
        if (_inited)
            return;
        if (Token == null) {
            return;
        }
        if (!_foreground)
            return;
        _inited = true;
        if defined(iOS) 
            InitImpl(Token);
    }

    [Require("Cocoapods.Podfile.Target", "pod 'HockeySDK'")]
    [Require("Source.Declaration", "#import \"HockeySDK/HockeySDK.h\"")]
    [Foreign(Language.ObjC)]
    extern(iOS) void InitImpl(string token) 
    @{
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:token];
        // Do some additional configuration if needed here
        [[BITHockeyManager sharedHockeyManager] startManager];
        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation]; // This line is obsolete in the crash only builds
    @}

    static string _token;
    public string Token {
        get { return _token; } 
        set { 
            _token = value;
            Init();
        }
    }
}
