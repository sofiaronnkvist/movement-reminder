
import Toybox.Application;
import Toybox.WatchUi;

class Main extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        // Called when the app starts
    }

    function onStop(state) {
        // Called when the app exits
    }

    function getInitialView() {
        var view = new MovementReminderView();
        return [ view, new MovementReminderDelegate(view) ];
    }
}
