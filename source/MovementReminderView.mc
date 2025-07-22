
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Graphics;
import Toybox.Lang;
using Toybox.Application as App;

class MovementReminderView extends WatchUi.View {

    var _showingReminder;

    function initialize() {
        View.initialize();
        _showingReminder = false;
    }

    /**
     * Widget display - minimal info during idle state
     */
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Just show time for now
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var timeString = Lang.format("$1$:$2$", [info.hour.format("%02d"), info.min.format("%02d")]);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        if (_showingReminder) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 25, Graphics.FONT_SMALL, "TIME TO MOVE!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 15, Graphics.FONT_TINY, "Move for 3 minutes", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(centerX, centerY - 25, Graphics.FONT_SMALL, "Move Reminder", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, centerY + 15, Graphics.FONT_TINY, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    function triggerReminder() {
        _showingReminder = true;
        WatchUi.requestUpdate();
    }
    
    function dismissReminder() {
        _showingReminder = false;
        WatchUi.requestUpdate();
    }
    
    function isShowingReminder() {
        return _showingReminder;
    }
}

// Add behavior delegate to handle button presses
class MovementReminderDelegate extends WatchUi.BehaviorDelegate {
    
    var _app;
    
    function initialize(app) {
        BehaviorDelegate.initialize();
        _app = app;
    }
    
    function onSelect() {
        // Dismiss reminder when select/start button is pressed
        if (_app != null) {
            _app.dismissReminderManually();
        }
        return true;
    }
}
