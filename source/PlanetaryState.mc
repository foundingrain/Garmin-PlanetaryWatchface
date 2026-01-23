import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Planetary {
    class State {
        public var hour, min, sec; 
        public var dow, day, month, year;
        public var batt;

        public function initialize() {
            hour = 0; min = 0; sec = 0;
            dow = 0; day = 0; month = 0; year = 0;
            batt = 0;
        }
        public function update() {
            var now = System.getClockTime();
            var greg = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var sys = System.getSystemStats();

            hour = now.hour;
            min = now.min;
            sec = now.sec;

            dow = greg.day_of_week;
            day = greg.day;
            month = greg.month;
            year = greg.year;

            batt = sys.battery;
        }
    }
}

