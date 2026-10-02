import QtQuick

// One island command. Each command lives in its own file and overrides run();
// suggest() may return [{ label, value }] completions for the argument.
QtObject {
    property string name
    property string icon: "terminal"
    property string args: ""          // shown as a hint, e.g. "<name>"
    property string description
    property bool keepOpen: false     // true when run() switches the island to a view
    property int revision: 0          // bump when suggestions change asynchronously

    function run(arg) {}
    function suggest(arg) {
        return [];
    }
}
