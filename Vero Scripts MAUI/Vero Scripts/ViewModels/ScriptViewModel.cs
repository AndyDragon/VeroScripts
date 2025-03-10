using VeroScripts.Base;

namespace VeroScripts.ViewModels;

public class ScriptViewModel(FeatureViewModel viewModel, Script script) : NotifyPropertyChanged
{
    public FeatureViewModel ViewModel { get; } = viewModel;
    public Script Script { get; } = script;
    
    public string NextScript
    {
        get
        {
            return Script switch
            {
                Script.Feature => "Comment script \u27a4",
                Script.Comment => "Original post script \u27a4",
                Script.OriginalPost => "New membership \u27a4",
                _ => throw new ArgumentOutOfRangeException()
            };
        }
    }

    public string ScriptTitle => ViewModel.GetScriptTitle(Script);

    public string ScriptText
    {
        get => ViewModel.GetScriptText(Script);
        set
        {
            if (ViewModel.SetScriptText(Script, value))
            {
                OnPropertyChanged(nameof(ScriptLength));
                OnPropertyChanged(nameof(ScriptHasPlaceholders));
            }
        }
    }
    
    public int ScriptLength => ViewModel.GetScriptLength(Script);
    
    public bool ScriptHasPlaceholders => ViewModel.GetScriptHasPlaceholders(Script);
}
