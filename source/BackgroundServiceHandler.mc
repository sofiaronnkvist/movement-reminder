
import Toybox.System;
import Toybox.Background;
import Toybox.Time;
import Toybox.Attention;
import Toybox.Application;
import Toybox.Lang;

class BackgroundServiceHandler extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        var now = Time.now();
        var gregorianInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var nowSecs = gregorianInfo.hour * 3600 + gregorianInfo.min * 60 + gregorianInfo.sec;

        // Load settings
        var reminderMin = Application.Properties.getValue("reminderInterval");
        if (reminderMin == null) { reminderMin = 30; }
        var reminderInterval = reminderMin.toNumber() * 60;

        var startStr = Application.Properties.getValue("startHour");
        if (startStr == null) { startStr = "07:00"; }
        var endStr = Application.Properties.getValue("endHour");
        if (endStr == null) { endStr = "22:00"; }

        var startSecs = _parseHMS(startStr);
        var endSecs = _parseHMS(endStr);

        // Only remind during active hours
        if (nowSecs >= startSecs && nowSecs <= endSecs) {
            var lastReminderTs = Application.Storage.getValue("lastReminderTs");
            if (lastReminderTs == null) { lastReminderTs = 0; }

            var nowTime = now.value();
            if ((nowTime - lastReminderTs) >= reminderInterval) {
                // Trigger attention signals
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
                // Persist state so foreground widget can restore alert UI
                Application.Storage.setValue("lastReminderTs", nowTime);
                Application.Storage.setValue("reminderActive", true);
            }
        }

        // Schedule the next background check
        Background.registerForTemporalEvent(new Time.Duration(reminderInterval));
    }

    function _parseHMS(t) {
        var colonIndex = t.find(":");
        if (colonIndex == null) { return 0; }
        var hourStr = t.substring(0, colonIndex);
        var minStr = t.substring(colonIndex + 1, t.length());
        return (hourStr.toNumber() * 3600) + (minStr.toNumber() * 60);
    }
}
