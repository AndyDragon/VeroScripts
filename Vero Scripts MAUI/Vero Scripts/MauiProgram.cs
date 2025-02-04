﻿using CommunityToolkit.Maui;
using MauiIcons.Material.Rounded;
#if DEBUG
using Microsoft.Extensions.Logging;
#endif

namespace VeroScripts;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSans");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemiBold");
                fonts.AddFont("OpenSans-Bold.ttf", "OpenSansBold");
                fonts.AddFont("OpenSans-ExtraBold.ttf", "OpenSansExtraBold");
            })
            .UseMaterialRoundedMauiIcons();

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}
