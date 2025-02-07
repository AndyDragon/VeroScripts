export const applicationName = "Vero Scripts";
export const applicationDescription = "Vero Scripts is a productivity tool for Vero hub page admins and moderators.";
export const applicationDetails = (
    <>
        This tool is used to format the feature, comment and post scripts for features. The tool includes the snap pages and
        a few other hub pages as well. This tool takes the information entered at the top and produces the three main scripts
        as well as an optional fourth script if the user has been promoted to a new membership level. Some of the fields which
        stay consistent like your user name, your first name, the page and your page staff level are stored in user
        preferences and reloaded when the app is started again. Since the pages are stored on a server and loaded at start up
        changes to the script templates do not require a new version of the application, the app just needs to be restarted.
    </>
);
export const macScreenshotWidth = 1200;
export const macScreenshotHeight = 820;
export const windowsScreenshotWidth = 1200;
export const windowsScreenshotHeight = 800;

export const deploymentWebLocation = "/app/veroscripts";

export const versionLocation = "veroscripts/version.json";

export const enum PlatformLocation {
    DoNotShow,
    AppPortal,
    AppStore,
}

export const showMacInfo: PlatformLocation = PlatformLocation.AppStore;
export const macAppStoreLocation = "https://apps.apple.com/ca/app/vero-scripts/id6475614720";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const showIosInfo: PlatformLocation = PlatformLocation.AppStore;
export const iosAppStoreLocation = "https://apps.apple.com/ca/app/vero-scripts/id6475614720";
export const iosReleaseNotesLocation = "releaseNotes-ios.json";

export const showWindowsInfo: PlatformLocation = PlatformLocation.AppPortal;
export const windowsInstallerLocation = "veroscripts/windows";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export const showAndroidInfo: PlatformLocation = PlatformLocation.DoNotShow;
export const androidInstallerLocation = "TODO";
export const androidReleaseNotesLocation = "releaseNotes-android.json";

export const supportEmail = "andydragon@live.com";

export const hasTutorial = false;

export type Platform = "macOS" | "windows" | "iOS" | "android";

export const platformString: Record<Platform, string> = {
    macOS: "macOS",
    windows: "Windows",
    iOS: "iPhone / iPad",
    android: "Android",
}

export interface Links {
    readonly useAppStore?: true;
    readonly location: (version: string, flavorSuffix: string) => string;
    readonly actions: {
        readonly action: string;
        readonly target: string;
        readonly suffix: string;
    }[];
}

export const links: Record<Platform, Links | undefined> = {
    macOS: {
        useAppStore: true,
        location: (_version, _suffix) => macAppStoreLocation,
        actions: [
            {
                action: "install from app store",
                target: "",
                suffix: "",
            }
        ]
    },
    iOS: {
        useAppStore: true,
        location: (_version, _suffix) => iosAppStoreLocation,
        actions: [
            {
                action: "install from app store",
                target: "",
                suffix: "",
            }
        ]
    },
    windows: {
        location: (_version, suffix) => `${windowsInstallerLocation}${suffix}`,
        actions: [
            {
                action: "install the current version",
                target: "",
                suffix: "/setup.exe",
            },
            {
                action: "read more about the app",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    android: {
        useAppStore: true,
        location: (_version, _suffix) => androidInstallerLocation,
        actions: [
            {
                action: "install from app store",
                target: "",
                suffix: "",
            }
        ]
    },
};

export interface NextStep {
    readonly label: string;
    readonly page: string;
}

export interface Screenshot {
    readonly name: string;
    readonly width?: string;
}

export interface Bullet {
    readonly text: string;
    readonly image?: Screenshot;
    readonly screenshot?: Screenshot;
    readonly link?: string;
}

export interface PageStep {
    readonly screenshot: Screenshot;
    readonly title: string;
    readonly bullets: Bullet[];
    readonly previousStep?: string;
    readonly nextSteps: NextStep[];
}

export const tutorialPages: Record<string, PageStep> = {
};
