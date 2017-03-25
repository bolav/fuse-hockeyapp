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

[ForeignInclude(Language.Java,
    "net.hockeyapp.android.CrashManager",
    "net.hockeyapp.android.UpdateManager")]
public class HockeyApp : Behavior {
    public HockeyApp () {
        debug_log "Constructor";
        if defined(DESIGNMODE)
            return;
        Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
        if ((Fuse.Platform.Lifecycle.State == Fuse.Platform.ApplicationState.Foreground)
            || (Fuse.Platform.Lifecycle.State == Fuse.Platform.ApplicationState.Interactive)
            ) {
            _foreground = true;
        }
        if defined(Android) {
            Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground; // onpause
            Fuse.Platform.Lifecycle.Terminating += OnTerminating; // ondestroy
        }
    }

    void OnEnteringForeground(Fuse.Platform.ApplicationState newState)
    {
        _foreground = true;
        if defined(!Android) Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
        Init();
        if defined(Android) CheckForUpdates();
    }

    void OnEnteringBackground(Fuse.Platform.ApplicationState newState)
    {
        if defined(Android) UnregisterManagers();
    }

    void OnTerminating(Fuse.Platform.ApplicationState newState)
    {
        if defined(Android) UnregisterManagers();
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

    [Require("Gradle.Dependency.Compile", "net.hockeyapp.android:HockeySDK:4.1.3")]
    [Require("AndroidManifest.ApplicationElement", "<meta-data android:name=\"net.hockeyapp.android.appIdentifier\" android:value=\"@(Project.HockeyApp.AndroidToken)\" />")]
    [Foreign(Language.Java)]
    extern(Android) void InitImpl(string token)
    @{
        UpdateManager.register(com.fuse.Activity.getRootActivity());
    @}

    [Foreign(Language.Java)]
    extern(Android) void UnregisterManagers()
    @{
        UpdateManager.unregister();
    @}

    [Foreign(Language.Java)]
    extern(Android) void CheckForUpdates()
    @{
        UpdateManager.register(com.fuse.Activity.getRootActivity());
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
