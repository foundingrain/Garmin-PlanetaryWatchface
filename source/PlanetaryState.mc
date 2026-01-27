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

        // Slow updates 
        public var dow, day, month, year;
        public var sunrise, sunset;
        public var hourlyForecast;

        private var _lastSlowKey;

        public function initialize() {
            hour = 0; min = 0; sec = 0;
            dow = 0; day = 0; month = 0; year = 0;
            batt = 0;
            sunrise = null;
            sunset = null;
            hourlyForecast = null;
            _lastSlowKey = null;
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
            var pos = Position.getInfo();

            dow = greg.day_of_week;
            day = greg.day;
            month = greg.month;
            year = greg.year;

            // Position-based Modules
            if (pos != null && pos.position != null) {
                updateSunEventTimes(pos);
                updateHourlyForecast(pos);
            }
        }
        private function updateSunEventTimes(pos as Position.Info) {
            var sr = Weather.getSunrise(pos.position, Time.now());
            var ss = Weather.getSunset(pos.position, Time.now());

            if (sr != null && ss != null) {
                var srLocal = Time.Gregorian.info(sr, Time.FORMAT_SHORT);
                var ssLocal = Time.Gregorian.info(ss, Time.FORMAT_SHORT);

                sunrise = ((srLocal.hour * 60) + srLocal.min) % 1440;
                sunset = ((ssLocal.hour * 60) + ssLocal.min) % 1440;
            }
        }
        private function updateHourlyForecast(pos as Position.Info) {
            var hf = Weather.getHourlyForecast();

            if (hf != null) {
                hourlyForecast = hf;
            }
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
    }
}

