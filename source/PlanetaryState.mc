import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Position;

module Planetary {
    class State {
        // Fast updates
        public var hour, min, sec;
        public var batt;
        public var showSeconds;

        // Slow updates 
        public var dow, day, month, year;

        private var _lastSlowKey;
        private var _glanceTime;

        public function initialize() {
            hour = 0; min = 0; sec = 0;
            dow = 0; day = 0; month = 0; year = 0;
            batt = 0;
            showSeconds = false;
            _lastSlowKey = null;
            _glanceTime = 0;
        }

        public function updateFast() {
            var now = System.getClockTime();
            var sys = System.getSystemStats();

            hour = now.hour;
            min = now.min;
            sec = now.sec;

            batt = sys.battery;
        }

        public function updateSlow() {
            var greg = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

            dow = greg.day_of_week;
            day = greg.day;
            month = greg.month;
            year = greg.year;
        }

        public function shouldRunSlow(intervalMin as Number) as Boolean {
            var bucket = (min / intervalMin).toNumber();
            var key = (year * 10000000) + (month * 10000) + (day * 100) + bucket;

            if (_lastSlowKey == null || key != _lastSlowKey) {
                _lastSlowKey = key;
                return true;
            }
            return false;
        }

        public function onGlance() as Void {
            showSeconds = true;
            _glanceTime = System.getTimer();
        }
        public function tickGlance(delayMs as Number) as Void {
            if (showSeconds && (System.getTimer() - _glanceTime) > delayMs) {
                showSeconds = false;
            }
        }
    }
}

