
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Background;

class MovementReminderApp extends Application.AppBase {

    var _reminderInterval;    // seconds
    var _movementDuration;    // seconds
    var _startSecs;           // seconds since midnight
    var _endSecs;             // seconds since midnight
    var _lastReminderTs;      // epoch seconds
    var _stepsAtReminder;     // step count when reminder was triggered (-1 if unavailable)
    var _timer;
    var _view;

    function initialize() {
        AppBase.initialize();
        _loadSettings();
        // Restore last reminder timestamp from persistent storage (set by background handler)
        var stored = Application.Storage.getValue("lastReminderTs");
        _lastReminderTs = (stored != null) ? stored : 0;
        _stepsAtReminder = -1;
        _timer = null;
    }

    function onStart(state) {
        // Register next background temporal event (Background module is safe in both contexts)
        Background.registerForTemporalEvent(new Time.Duration(_reminderInterval));

        // Inline background-safe reminder check.
        // WatchUi, Timer, and Graphics are NOT available in background context,
        // so we cannot call _triggerReminder() or _startDisplayTimer() here.
        var now = Time.now();
        var gregorianInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var nowSecs = gregorianInfo.hour * 3600 + gregorianInfo.min * 60 + gregorianInfo.sec;

        if (nowSecs >= _startSecs && nowSecs <= _endSecs) {
            var nowTime = now.value();
            if ((nowTime - _lastReminderTs) >= _reminderInterval) {
                _lastReminderTs = nowTime;
                Application.Storage.setValue("lastReminderTs", _lastReminderTs);
                Application.Storage.setValue("reminderActive", true);

                if (Attention has :vibrate) {
                    var vibeData = [
                        new Attention.VibeProfile(50, 1000),
                        new Attention.VibeProfile(0, 200),
                        new Attention.VibeProfile(75, 1000)
                    ];
                    Attention.vibrate(vibeData);
                }
                if (Attention has :playTone) {
                    Attention.playTone(Attention.TONE_ALARM);
                }
            }
        }
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
        // Restore alert state if a reminder fired while the widget was closed
        var reminderActive = Application.Storage.getValue("reminderActive");
        if (reminderActive != null && reminderActive) {
            _view.triggerReminder();
        }
        // Start the foreground display timer (Timer only available in foreground context)
        _startDisplayTimer();
        return [ _view, new MovementReminderDelegate(self) ];
    }
    
    function _loadSettings() {
        var reminderMin = Application.Properties.getValue("reminderInterval");
        if (reminderMin == null) { reminderMin = 30; }
        _reminderInterval = reminderMin.toNumber() * 60;

        var movementMin = Application.Properties.getValue("movementDuration");
        if (movementMin == null) { movementMin = 3; }
        _movementDuration = movementMin.toNumber() * 60;

        var startStr = Application.Properties.getValue("startHour");
        if (startStr == null) { startStr = "07:00"; }

        var endStr = Application.Properties.getValue("endHour");
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
    
    function _startDisplayTimer() {
        // Update display and check for reminders more frequently when app is active
        if (_timer == null) {
            _timer = new Timer.Timer();
            _timer.start(method(:_updateAndCheck), 5000, true); // Every 5 seconds, repeat
        }
    }
    
    function _updateAndCheck() as Void {
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
        
        // Movement-based auto-dismissal
        if (_view != null && _view.isShowingReminder()) {
            // Primary: check if the user has taken 20+ steps since the reminder fired
            if (_stepsAtReminder >= 0) {
                var activityInfo = ActivityMonitor.getInfo();
                if (activityInfo != null && activityInfo.steps != null &&
                    (activityInfo.steps - _stepsAtReminder) >= 20) {
                    dismissReminderManually();
                    return;
                }
            }
            // Fallback: auto-dismiss after movementDuration seconds if step data unavailable
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
        // Persist so background handler and foreground stay in sync
        Application.Storage.setValue("lastReminderTs", _lastReminderTs);
        Application.Storage.setValue("reminderActive", true);

        // Record step count at the moment of reminder for movement detection
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo != null && activityInfo.steps != null) {
            _stepsAtReminder = activityInfo.steps;
        } else {
            _stepsAtReminder = -1;
        }

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
        // Reset timer and clear alert UI
        if (_view != null) {
            _view.dismissReminder();
        }
        _lastReminderTs = Time.now().value();
        _stepsAtReminder = -1;
        // Persist dismissal so background handler knows to reset
        Application.Storage.setValue("lastReminderTs", _lastReminderTs);
        Application.Storage.setValue("reminderActive", false);
    }
}
