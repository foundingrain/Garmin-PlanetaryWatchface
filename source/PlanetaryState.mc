import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Position;

module Planetary {
    class State {
        public var hour, min, sec; 
        public var dow, day, month, year;
        public var batt;
        public var sunrise, sunset;

        public function initialize() {
            hour = 0; min = 0; sec = 0;
            dow = 0; day = 0; month = 0; year = 0;
            batt = 0;
            sunrise = null;
            sunset = null;
        }
        // TODO: Separate fast and slow updates
        public function update() {
            var now = System.getClockTime();
            var greg = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var sys = System.getSystemStats();
            var pos = Position.getInfo();

            hour = now.hour;
            min = now.min;
            sec = now.sec;

            dow = greg.day_of_week;
            day = greg.day;
            month = greg.month;
            year = greg.year;

            batt = sys.battery;

            // Sunrise / Sunset (Needs permission)
            if (pos != null && pos.position != null) {
                var sr = Weather.getSunrise(pos.position, Time.now());
                var ss = Weather.getSunset(pos.position, Time.now());

                if (sr != null && ss != null) {
                    var srLocal = Time.Gregorian.info(sr, Time.FORMAT_SHORT);
                    var ssLocal = Time.Gregorian.info(ss, Time.FORMAT_SHORT);

                    sunrise = ((srLocal.hour * 60) + srLocal.min) % 1440;
                    sunset = ((ssLocal.hour * 60) + ssLocal.min) % 1440;
                }
            }
        }
    }
}

