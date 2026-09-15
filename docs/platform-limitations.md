# Apple platform limitations

Reviewed against public Apple documentation on 2026-09-15. These are engineering constraints, not claims that third-party workarounds cannot exist. Recheck them when expanding the minimum OS versions.

## Apple Watch: distinguish Auto Unlock from ordinary Bluetooth

Apple describes a secure Auto Unlock exchange between supported devices. This is an OS feature, not a public developer feed of Watch presence or distance. There is no supported Watch-away auto-lock setting or public Auto Unlock proximity API used by this project. That API-availability conclusion is our assessment of the public platform surface, not a quoted Apple guarantee about all future OS versions.

Sources: [Apple Platform Security: automatically unlock Apple devices](https://support.apple.com/guide/security/automatically-unlock-apple-devices-sec6ab47ebfc/web), [Unlock your Mac with Apple Watch](https://support.apple.com/en-us/102442).

That does **not** mean all Watch proximity sensing is impossible. A stock Watch or iPhone may be discoverable/connectable through ordinary Core Bluetooth. We now attempt a selected-device connection and poll its RSSI, with advertisements as fallback. Discovery, identity stability, and connection acceptance must be tested on the actual device. On 2026-09-15, this implementation established a public Core Bluetooth connection to an owner-confirmed Apple Watch and received repeated connected RSSI readings on macOS 27. Physical walk-away locking still requires separate validation; this is one hardware observation, not a universal compatibility guarantee.

Do not scrape private Continuity/Auto Unlock logs, reverse-engineer Watch identifiers, or present a Bluetooth name as authenticated ownership. WatchConnectivity supports communication between a watchOS app and its paired iOS app; it is not a general Mac-to-Watch proximity channel. A future companion still needs independent feasibility work.

## Active BLE connection first; passive discovery is a fallback

Core Bluetooth discovers advertising BLE peripherals. A device being paired in system Bluetooth settings does not mean it publishes discoverable advertisements with a stable identity for this application. RSSI fluctuates with orientation, obstacles, and radio traffic. It is not a meter estimate. The active path uses public [connect](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/connect(_:options:)) and [readRSSI](https://developer.apple.com/documentation/corebluetooth/cbperipheral/readrssi()) calls; it does not need to read application data or protected GATT characteristics. A successful connection is still not proof of identity.

iOS background peripheral advertising differs from foreground behavior: the local name is omitted and service identifiers move to an overflow area discoverable by an iOS device explicitly scanning for them. Therefore, a naive iPhone advertiser plus Mac scanner is not a demonstrated background solution. A future design may need a maintained, authenticated GATT connection, a different central/peripheral arrangement, or another signal. Test suspension, force-quit, phone lock, power saving, and reconnect behavior.

Sources: [Core Bluetooth background processing for iOS](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html), [CBPeripheralManager.startAdvertising](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/startadvertising(_:)).

## Focus: shared state is the supported MVP route

Apple documents that turning Focus on/off propagates between devices signed into the same Apple Account when **Share Across Devices** is enabled. Consequently, running a Mac shortcut can affect the iPhone, but also affects the Mac. Shared Focus settings can also synchronize; do not assume separate app allow/silence lists can solve this per device. Focus filters are a different feature and do not provide general notification routing.

If sharing is disabled to preserve independent Mac notifications, this bridge cannot remotely enable an iPhone-only Focus. The earlier idea of combining iPhone-only Focus with direct Mac Shortcuts control needs a separate transport and an iOS-supported execution mechanism. It is not delivered by this MVP.

Sources: [Manage Focus options on Mac](https://support.apple.com/guide/mac-help/mchl74e8c77b/mac), [Set up a Focus on iPhone](https://support.apple.com/guide/iphone/iphd6288a67f/ios).

`INFocusStatusCenter` gives authorized access to notification availability; it does not expose a setter for arbitrary Focus modes or disclose a general named-Focus control API. App Intents/Focus filters do not grant arbitrary cross-device Focus control. The MVP uses user-configured Shortcuts instead.

Source: [INFocusStatusCenter](https://developer.apple.com/documentation/intents/infocusstatuscenter).

## Shortcuts sync does not remotely execute an iPhone shortcut

The Mac `shortcuts` command runs on the Mac. iCloud syncing a shortcut definition does not run it on another device. iPhone personal automations require supported triggers and are device-specific. The baseline documented Bluetooth trigger is a connection event, not continuous distance sensing; do not equate it with Watch proximity or assume every OS has a matching disconnect trigger.

The project does not treat a URL, an iCloud file update, a silent push, or an arbitrary webhook as permission to execute a phone shortcut unattended. Future OS trigger additions need separate validation. An optional relay service may carry subscription, extra-device, privacy, and execution constraints and is outside the default architecture.

Sources: [Run shortcuts from the command line](https://support.apple.com/guide/shortcuts-mac/apd455c82f02/mac), [Intro to personal automation](https://support.apple.com/guide/shortcuts/apd690170742/ios), [Setting triggers](https://support.apple.com/guide/shortcuts/apde31e9638b/ios).

## Locking and session observation

Apple documents Control-Command-Q as the lock-screen shortcut. The app requests that shortcut using public Core Graphics event posting with Accessibility permission. It cannot prove the system accepted the request. Keyboard remapping, permission changes, secure input, or OS behavior may prevent it; verify on the target Mac. Successful posting is never reported as confirmed locking.

Workspace screen-sleep and session notifications do not prove authentication has completed. Thus this MVP asks for a menu interaction after return. It uses no undocumented `CGSession` executable, private screen-lock function, or Apple Watch unlock implementation.

Sources: [Mac keyboard shortcuts](https://support.apple.com/en-us/102650), [Core Graphics input timing](https://developer.apple.com/documentation/coregraphics/cgeventsource/secondssincelasteventtype(_:eventtype:)), [NSWorkspace session notifications](https://developer.apple.com/documentation/appkit/nsworkspace/sessiondidresignactivenotification).
