
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
using Toybox.Application as App;

class MovementReminderView extends WatchUi.View {

    var _reminderInterval;    // seconds
    var _movementDuration;    // seconds
    var _startSecs;           // seconds since midnight
    var _endSecs;             // seconds since midnight
    var _lastReminderTs;      // epoch seconds
    var _showingReminder;     // boolean to show reminder message

    function initialize() {
        View.initialize();
        _loadSettings();
        _lastReminderTs = 0;
        _showingReminder = false;
    }

    /**
     * Load user‑defined settings (or defaults)
     */
    function _loadSettings() {
        var reminderMin = App.getApp().getProperty("reminderInterval");
        if (reminderMin == null) { reminderMin = 30; }  // 30 minutes default
        _reminderInterval = reminderMin.toNumber() * 60;  // Convert minutes to seconds
        
        var movementMin = App.getApp().getProperty("movementDuration");
        if (movementMin == null) { movementMin = 3; }
        _movementDuration = movementMin.toNumber() * 60;

        var startStr = App.getApp().getProperty("startHour");
        if (startStr == null) { startStr = "07:00"; }
        
        var endStr = App.getApp().getProperty("endHour");
        if (endStr == null) { endStr = "22:00"; }
        _startSecs = _parseHMS(startStr);
        _endSecs   = _parseHMS(endStr);
    }

    /**
     * Parse "HH:MM" into seconds since midnight
     */
    function _parseHMS(t) {
        var colonIndex = t.find(":");
        if (colonIndex == null) {
            return 0;
        }
        var hourStr = t.substring(0, colonIndex);
        var minStr = t.substring(colonIndex + 1, t.length());
        return (hourStr.toNumber() * 3600) + (minStr.toNumber() * 60);
    }

    /**
     * Main view drawing method
     */
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        if (_showingReminder) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 30, Graphics.FONT_LARGE, 
                       "TIME TO MOVE!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 20, Graphics.FONT_SMALL, 
                       "Move for " + (_movementDuration/60).toString() + " minutes", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_MEDIUM, 
                       "Movement\nReminder", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        
        _checkForReminder();
    }
    
    /**
     * Check if we should show a reminder
     */
    function _checkForReminder() {
        var now = Time.now();
        var gregorianInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var nowSecs = gregorianInfo.hour * 3600 + gregorianInfo.min * 60 + gregorianInfo.sec;

        // Skip if outside active hours
        if (!(nowSecs >= _startSecs && nowSecs <= _endSecs)) {
            return;
        }

        var nowTime = now.value();
        
        // Skip if we have already reminded within this interval
        if ((nowTime - _lastReminderTs) < _reminderInterval) {
            return;
        }

        // For simplicity, trigger reminder based on time interval
        // In a real app, you'd check actual activity data
        if ((nowTime - _lastReminderTs) >= _reminderInterval) {
            _triggerReminder();
        }
    }

    /**
     * Show alert + vibrate
     */
    function _triggerReminder() {
        _lastReminderTs = Time.now().value();
        _showingReminder = true;
        
        // Vibrate to get attention
        if (System has :vibrate) {
            System.vibrate([1000, 200, 1000]);
        }
        
        // Request the view to update to show the reminder
        WatchUi.requestUpdate();
    }
    
    /**
     * Dismiss the current reminder
     */
    function dismissReminder() {
        _showingReminder = false;
        WatchUi.requestUpdate();
    }
}

class MovementReminderDelegate extends WatchUi.BehaviorDelegate {
    
    var _view;
    
    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    
    function onSelect() {
        _view.dismissReminder();
        return true;
    }
    
    function onBack() {
        System.exit();
        return true;
    }
}
