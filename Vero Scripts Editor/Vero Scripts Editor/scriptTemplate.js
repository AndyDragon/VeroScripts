return {
    // Set defaultToken to invalid to see what you do not tokenize yet
    defaultToken: '',
    tokenPostfix: '.template',

    keywords: [
        '%%PAGENAME%%',
        '%%FULLPAGENAME%%',
        '%%PAGETITLE%%',
        '%%PAGEHASH%%',
        '%%USERNAME%%',
        '%%MEMBERLEVEL%%',
        '%%YOURNAME%%',
        '%%YOURFIRSTNAME%%',
        '%%STAFFLEVEL%%',
    ],

    // brackets: [
    //     { open: "%%", close: "%%", token: 'variable.other.constant' },
    //     { open: "[[", close: "]]", token: 'variable.other.constant' },
    //     { open: "[{", close: "}]", token: 'variable.other.variable' },
    // ],

    // autoClosingPairs: [
    //   ["%%", "%%"],
    //   ["[[", "]]"],
    //   ["[{", "}]"],
    // ],

    // surroundingPairs: [
    //   ["%%", "%%"],
    //   ["[[", "]]"],
    //   ["[{", "}]"],
    // ],

    // The main tokenizer for our languages
    tokenizer: {
        root: [
            // keywords
            [/%%[A-Za-z0-9\s]*%%/, { cases: { '@keywords': 'keyword', '@default': 'invalid' } }],
            [/\[\[([A-Za-z0-9\s]*)\]\]/, { cases: { '@default': 'type.static' } }],
            [/\[\{[A-Za-z0-9\s]*\}\]/, { cases: { '@default': 'regexp' } }],

            //[/[\[{}\]]/, '@brackets'],
        ],
    },
};
