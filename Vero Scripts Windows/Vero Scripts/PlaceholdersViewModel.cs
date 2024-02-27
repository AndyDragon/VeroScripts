﻿using System;
using System.Collections.ObjectModel;
using System.ComponentModel;

namespace VeroScripts
{
    public partial class PlaceholdersViewModel(ScriptsViewModel scriptViewModel, Script script)
    {
        public ScriptsViewModel ScriptsViewModel { get; private set; } = scriptViewModel;

        public ObservableCollection<Placeholder> Placeholders { get; private set; } = scriptViewModel.PlaceholdersMap[script];
    }
}
