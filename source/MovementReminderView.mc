
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Graphics;
import Toybox.Lang;
using Toybox.Application as App;

class MovementReminderView extends WatchUi.View {

    var _showingReminder;
    var _app;

    function initialize() {
        View.initialize();
        _showingReminder = false;
        _app = Application.getApp();
    }

    /**
     * App display - show movement reminder status and countdown
     */
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        if (_showingReminder) {
            // Active reminder display
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 60, Graphics.FONT_LARGE, "TIME TO MOVE!", Graphics.TEXT_JUSTIFY_CENTER);
            
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 5, Graphics.FONT_TINY, "Press SELECT to dismiss", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Normal app display with countdown
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 40, Graphics.FONT_MEDIUM, "Movement Reminder", Graphics.TEXT_JUSTIFY_CENTER);
            
            // Calculate and display countdown
            var countdownText = _getCountdownText();
            if (countdownText != null) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, centerY - 5, Graphics.FONT_SMALL, "Next reminder in:", Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(centerX, centerY + 20, Graphics.FONT_LARGE, countdownText, Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, centerY + 5, Graphics.FONT_SMALL, "Outside active hours", Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }
    
    function _getCountdownText() {
        // Get current time and settings
        var now = Time.now();
        var nowTime = now.value();
        var gregorianInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var nowSecs = gregorianInfo.hour * 3600 + gregorianInfo.min * 60 + gregorianInfo.sec;
        
        // Load settings
        var reminderMin = Application.Properties.getValue("reminderInterval");
        if (reminderMin == null) { reminderMin = 2; }
        var reminderInterval = reminderMin.toNumber() * 60; // Convert to seconds
        
        var startStr = Application.Properties.getValue("startHour");
        if (startStr == null) { startStr = "08:00"; }
        var endStr = Application.Properties.getValue("endHour");
        if (endStr == null) { endStr = "21:00"; }
        
        var startSecs = _parseHMS(startStr);
        var endSecs = _parseHMS(endStr);
        
        // Check if we're in active window
        if (!(nowSecs >= startSecs && nowSecs <= endSecs)) {
            return null; // Outside active hours
        }
        
        // Get last reminder time from app instance
        var lastReminderTs = 0;
        if (_app != null) {
            lastReminderTs = _app._lastReminderTs;
        }
        if (lastReminderTs == 0) { 
            return "Ready"; // No previous reminder, ready to trigger
        }
        
        // Calculate time until next reminder
        var timeSinceLastReminder = nowTime - lastReminderTs;
        var timeUntilNextReminder = reminderInterval - timeSinceLastReminder;
        
        if (timeUntilNextReminder <= 0) {
            return "Ready";
        }
        
        // Format the countdown
        var minutes = (timeUntilNextReminder / 60).toNumber();
        var seconds = (timeUntilNextReminder % 60).toNumber();
        
        if (minutes > 0) {
            return Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")]);
        } else {
            return Lang.format("0:$1$", [seconds.format("%02d")]);
        }
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
