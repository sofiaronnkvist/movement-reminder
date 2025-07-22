
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.Attention;
import Toybox.Background;

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
        // Start a timer to check for reminders and update the display
        _startDisplayTimer();
    }

    function onStop(state) {
        // Stop the timer when app is closed
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
        var reminderMin = Application.Properties.getValue("reminderInterval");
        if (reminderMin == null) { reminderMin = 2; }
        _reminderInterval = reminderMin.toNumber() * 60;
        
        var movementMin = Application.Properties.getValue("movementDuration");
        if (movementMin == null) { movementMin = 3; }
        _movementDuration = movementMin.toNumber() * 60;

        var startStr = Application.Properties.getValue("startHour");
        if (startStr == null) { startStr = "07:00"; }
        
        var endStr = Application.Properties.getValue("endHour");
        if (endStr == null) { endStr = "23:59"; }
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
    
    function _startDisplayTimer() {
        // Update display and check for reminders more frequently when app is active
        if (_timer == null) {
            _timer = new Timer.Timer();
            var callback = new Lang.Method(self, :_updateAndCheck);
            _timer.start(callback, 5000, true); // Every 5 seconds, repeat
        }
    }
    
    function _updateAndCheck() {
        // Check for reminders
        _checkForReminder();
        
        // Request a display update to refresh the countdown
        if (_view != null) {
            WatchUi.requestUpdate();
        }
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
        
        // Use Attention API for vibration and tones
        if (Attention has :vibrate) {
            var vibeData = [
                new Attention.VibeProfile(50, 1000),  // 50% intensity for 1000ms
                new Attention.VibeProfile(0, 200),    // Pause for 200ms
                new Attention.VibeProfile(75, 1000)   // 75% intensity for 1000ms
            ];
            Attention.vibrate(vibeData);
        }
        
        // Play tone if available
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALARM);
        }
        
        // Show notification if available
        if (Attention has :showNotification) {
            Attention.showNotification({
                :notificationText => "Time to move!",
                :backgroundColor => Graphics.COLOR_RED
            });
        }
        
        // Update the view if it exists (when app is open)
        if (_view != null) {
            _view.triggerReminder();
            WatchUi.requestUpdate();
        }
    }
    
    function dismissReminderManually() {
        // Reset and restart timer when manually dismissed
        if (_view != null) {
            _view.dismissReminder();
        }
        _lastReminderTs = Time.now().value(); // Reset timer manually
    }
}
