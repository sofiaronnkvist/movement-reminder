
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Activity;

class MovementReminderApp extends Application.AppBase {

    var _reminderInterval;    // seconds
    var _movementDuration;    // seconds  
    var _startSecs;           // seconds since midnight
    var _endSecs;             // seconds since midnight
    var _lastReminderTs;      // epoch seconds
    var _timer;
    var _view;

    function initialize() {
        AppBase.initialize();
        _loadSettings();
        _lastReminderTs = 0;
        _timer = null;
    }

    function onStart(state) {
        // Start the background timer for reminders
        _startReminderTimer();
    }

    function onStop(state) {
        // Stop the timer when widget is disabled
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function getInitialView() {
        _view = new MovementReminderView();
        return [ _view, new MovementReminderDelegate(self) ];
    }
    
    function _loadSettings() {
        var reminderMin = getProperty("reminderInterval");
        if (reminderMin == null) { reminderMin = 30; }
        _reminderInterval = reminderMin.toNumber() * 60;
        
        var movementMin = getProperty("movementDuration");
        if (movementMin == null) { movementMin = 3; }
        _movementDuration = movementMin.toNumber() * 60;

        var startStr = getProperty("startHour");
        if (startStr == null) { startStr = "07:00"; }
        
        var endStr = getProperty("endHour");
        if (endStr == null) { endStr = "22:00"; }
        _startSecs = _parseHMS(startStr);
        _endSecs = _parseHMS(endStr);
    }
    
    function _parseHMS(t) {
        var colonIndex = t.find(":");
        if (colonIndex == null) {
            return 0;
        }
        var hourStr = t.substring(0, colonIndex);
        var minStr = t.substring(colonIndex + 1, t.length());
        return (hourStr.toNumber() * 3600) + (minStr.toNumber() * 60);
    }
    
    function _startReminderTimer() {
        // Check every minute for production
        _timer = new Timer.Timer();
        var callback = new Lang.Method(self, :_checkForReminder);
        _timer.start(callback, 60000, true);
    }
    
    function _checkForReminder() {
        var now = Time.now();
        var gregorianInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var nowSecs = gregorianInfo.hour * 3600 + gregorianInfo.min * 60 + gregorianInfo.sec;

        // Skip if outside active hours
        if (!(nowSecs >= _startSecs && nowSecs <= _endSecs)) {
            return;
        }

        var nowTime = now.value();
        
        // Activity-based dismissal 
        if (_view != null && _view.isShowingReminder()) {
            // Auto-dismiss after movement duration (3 minutes default)
            if ((nowTime - _lastReminderTs) >= _movementDuration) {
                dismissReminderManually(); 
                return;
            }
        }

        // Skip if we have already reminded within this interval
        if ((nowTime - _lastReminderTs) < _reminderInterval) {
            return;
        }

        // Trigger reminder
        if ((nowTime - _lastReminderTs) >= _reminderInterval) {
            _triggerReminder();
        }
    }
    
    function _triggerReminder() {
        _lastReminderTs = Time.now().value();
        
        // Vibrate to get attention
        if (System has :vibrate) {
            System.vibrate([1000, 200, 1000]);
        }
        
        // Show visual reminder on widget
        if (_view != null) {
            _view.triggerReminder();
        }
        
        // Request widget update to show reminder
        WatchUi.requestUpdate();
    }
    
    function dismissReminderManually() {
        // Reset and restart timer when manually dismissed
        if (_view != null) {
            _view.dismissReminder();
        }
        _lastReminderTs = Time.now().value(); // Reset timer manually
    }
}
