
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Activity;
import Toybox.Application as App;

class MovementReminderView extends WatchUi.View {

    var _reminderInterval;    // seconds
    var _movementDuration;    // seconds
    var _startSecs;           // seconds since midnight
    var _endSecs;             // seconds since midnight
    var _lastReminderTs;      // epoch seconds

    function initialize() {
        View.initialize();
        _loadSettings();
        _lastReminderTs = 0;
    }

    /**
     * Load user‑defined settings (or defaults)
     */
    function _loadSettings() {
        _reminderInterval = ((App.getApp().getProperty("reminderInterval") || 30) * 60).toNumber();
        _movementDuration = ((App.getApp().getProperty("movementDuration") || 3) * 60).toNumber();

        var startStr = App.getApp().getProperty("startHour") ?: "07:00";
        var endStr   = App.getApp().getProperty("endHour")   ?: "22:00";
        _startSecs = _parseHMS(startStr);
        _endSecs   = _parseHMS(endStr);
    }

    /**
     * Parse "HH:MM" into seconds since midnight
     */
    function _parseHMS(t) {
        var parts = t.split(":");
        return (parts[0].toNumber() * 3600) + (parts[1].toNumber() * 60);
    }

    /**
     * Main update loop — runs once per second by default
     */
    function onUpdate(dc) {
        var now = Time.now();
        var nowSecs = now.hour * 3600 + now.min * 60 + now.sec;

        // Skip if outside active hours
        if (!(nowSecs >= _startSecs && nowSecs <= _endSecs)) {
            return;
        }

        // Skip if we have already reminded within this interval
        if ((now.value - _lastReminderTs) < _reminderInterval) {
            return;
        }

        var inactivity = now.value - Activity.getLastActivityTimestamp();

        if (inactivity >= _reminderInterval) {
            _triggerReminder();
        }
    }

    /**
     * Show alert + vibrate
     */
    function _triggerReminder() {
        _lastReminderTs = Time.now().value;
        // Simple on‑device popup
        WatchUi.simpleAlert("Time to Move!",
                            "Move for " + (_movementDuration/60).toString() + " min");
        System.vibrate(System.VIBE_LONG);
    }
}
