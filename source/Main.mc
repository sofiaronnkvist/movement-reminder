
import Toybox.Application;
import Toybox.WatchUi;

class MainApp extends Application.AppBase {

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
        return [ new MovementReminderView() ];
    }
}
