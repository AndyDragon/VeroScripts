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

export const macDmgLocation = "veroscripts/macos/Vero%20Scripts%20";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const windowsInstallerLocation = "veroscripts/windows";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export type Platform = "macOS" | "windows";

export const platformString: Record<Platform, string> = {
    macOS: "macOS",
    windows: "Windows"
}

export interface Links {
    readonly location: (version: string, flavorSuffix: string) => string;
    readonly actions: {
        readonly name: string;
        readonly action: string;
        readonly target: string;
        readonly suffix: string;
    }[];
}

export const links: Record<Platform, Links | undefined> = {
    macOS: {
        location: (version, suffix) => `${macDmgLocation}${suffix}v${version}.dmg`,
        actions: [
            {
                name: "default",
                action: "download",
                target: "",
                suffix: "",
            }
        ]
    },
    windows: {
        location: (_version, suffix) => `${windowsInstallerLocation}${suffix}`,
        actions: [
            {
                name: "current",
                action: "install",
                target: "",
                suffix: "/setup.exe",
            },
            {
                name: "current",
                action: "read more about",
                target: "_blank",
                suffix: "",
            }
        ]
    },
};
