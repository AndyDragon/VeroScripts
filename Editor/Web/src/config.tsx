export const applicationName = "Vero Scripts Editor";
export const applicationDescription = "Vero Scripts Editor is a utility tool for Vero hub page admins to author script templates.";
export const applicationDetails = (
    <>
        This tool is used to edit the script templates for the Vero Scripts tool.
    </>
);
export const macScreenshotWidth = 1320;
export const macScreenshotHeight = 800;
export const windowsScreenshotWidth = 1200;
export const windowsScreenshotHeight = 800;

export const deploymentWebLocation = "/app/veroscriptseditor";

export const versionLocation = "veroscriptseditor/version.json";

export const showMacInfo = true;
export const macDmgLocation = "veroscriptseditor/macos/Vero%20Scripts%20Editor%20";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const showWindowsInfo = false;
export const windowsInstallerLocation = "veroscriptseditor/windows";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export const hasTutorial = false;

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
