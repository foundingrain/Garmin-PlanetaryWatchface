import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;
import Planetary;

using Toybox.Graphics as Gfx;

module Planetary {
    class Renderer {
        private var cx, cy, radius;

        private const ORBITS = {
            :sol => 0.0,
            :mercury => 0.15,
            :venus => 0.30,
            :terra => 0.45,
            :mars => 0.60,
            :juputer => 0.75
        };

        private const FONTS = {
            :sec => Gfx.FONT_XTINY,
            :min => Gfx.FONT_XTINY,
            :hour => Gfx.FONT_XTINY,
            :day => Gfx.FONT_XTINY,
            :mon => Gfx.FONT_XTINY
        };
        // Helpers
        private function starStyleForBattery(batt as Number, baseR as Number) as Dictionary {
            var coreR, ringR, color, ringColor; 
            var ringCount = 1;

            if (batt > 75) { 
                coreR = baseR;
                ringR = baseR * 1.3;
                color = Gfx.COLOR_YELLOW;
                ringColor = Gfx.COLOR_WHITE;
            }
            else if (batt > 50){ 
                coreR = baseR * 1.3;
                ringR = baseR * 1.7;
                color = Gfx.COLOR_RED;
                ringColor = Gfx.COLOR_ORANGE;
            }
            else if (batt > 40) { 
                coreR = baseR * 0.9;
                ringR = baseR * 2.0;
                ringCount = 2;
                color = Gfx.COLOR_WHITE;
                ringColor = Gfx.COLOR_YELLOW;
            }
            else if (batt > 15){ 
                coreR = baseR * 0.6;
                ringR = baseR * 0.9;
                color = Gfx.COLOR_BLUE;
                ringColor = Gfx.COLOR_WHITE;
            }
            else { 
                coreR = baseR * 0.3;
                ringR = baseR * 0.6;
                color = Gfx.COLOR_BLACK;
                ringColor = Gfx.COLOR_DK_GRAY;
            }

            return {
                :coreR => coreR,
                :ringR => ringR,
                :ringCount => ringCount,
                :color => color,
                :ringColor => ringColor
            };
        }
        private function drawSunRay(dc as Dc, minsSinceMidnight, outerR as Number) {
           var m12 = minsSinceMidnight % 720;

           var a = (m12 * 2.0 * Math.PI / 720.0) - (Math.PI / 2.0);
           var x2 = cx + outerR * Math.cos(a);
           var y2 = cy + outerR * Math.sin(a);

            dc.drawLine(cx, cy, x2, y2);
        }
        private function getLastDayOfMonth(dc as Dc, s as Planetary.State) {
            var nextMonth = s.month + 1;
            var year = s.year;
            if (nextMonth > 12) {
                nextMonth = 1;
                year++;
            }
            var options = {
                :year => year,
                :month => nextMonth,
                :day => 1,
                :hour => s.hour,
                :minute => s.min,
                :second => s.sec
            };

            var when = Time.Gregorian.moment(options);
            var oneDay = new Time.Duration(Time.Gregorian.SECONDS_PER_DAY);
            when = when.subtract(oneDay);

            var info = Time.Gregorian.utcInfo(when, Time.FORMAT_SHORT);
            return info.day;
        }

        public function initialize() {
            cx = 0; cy = 0; radius = 0;
        }
        public function setDimensions(dc as Dc) {
            var w = dc.getWidth();
            var h = dc.getHeight();
            cx = w / 2;
            cy = h / 2;
            radius = ((w < h) ? w : h) / 2;
        }
        public function clear(dc as Dc) {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
            dc.clear();
        }

        public function render(dc as Dc, s as Planetary.State) {
            clear(dc);
            // drawDial(dc, s);
            // drawOrbitalLines(dc);

            // Background
            drawTimeSeparationLine(dc);

            // Status indicators
            // drawSunEventLines(dc, s);
            drawBatterySol(dc, s);

            // Time
            drawSecMercury(dc, s);
            drawMinVenus(dc, s);
            drawHourTerra(dc, s);
            drawDayMars(dc, s);
            drawMonthJupiter(dc, s);
            //drawYearSaturn(dc, s);

            // Date
            drawDowHighlight(dc, s);
        }
        public function drawDial(dc as Dc, s as Planetary.State) {
            var r = radius;

            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);

            for (var i = 0; i < 12; i++) {
                var angle = (i * 2.0 * Math.PI / 12.0) - (Math.PI / 2.0);
                var x = cx + (r * Math.cos(angle));
                var y = cy + (r * Math.sin(angle));

                dc.drawLine(cx, cy, x, y);
            }
        }
        private function drawOrbitalLines(dc as Dc) {
            dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
            for (var i = 0; i < ORBITS.size(); i++) {
                var r = radius * ORBITS[i];
                dc.drawCircle(cx, cy, r);
            }
        }
        private function drawTimeSeparationLine(dc as Dc) {
            var dots = 60;
            var dotr = radius * 0.01;
            var r = radius * (ORBITS[:terra] + (ORBITS[:mars] - ORBITS[:terra]) / 2.0);

            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            for (var i = 0; i < dots; i++) {
                var a = (i * 2.0 * Math.PI / dots);
                var x = cx + r * Math.cos(a);
                var y = cy + r * Math.sin(a);

                dc.fillCircle(x, y, dotr);
            }
        }
        private function drawSunEventLines(dc as Dc, s as Planetary.State) {
            if (s.sunrise == null || s.sunset == null) {
                return;
            }

            var len = radius * ORBITS[:terra];

            dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
            drawSunRay(dc, s.sunrise, len);
            
            dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
            drawSunRay(dc, s.sunset, len);
        }
        private function drawBatterySol(dc as Dc, s as Planetary.State) {
            var baseR = radius * 0.10;

            var star = starStyleForBattery(s.batt, baseR);

            // Core
            dc.setColor(star[:color], Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, star[:coreR]);

            // Rings
            dc.setColor(star[:ringColor], Gfx.COLOR_TRANSPARENT);
            for (var i = 0; i < star[:ringCount]; i++) {
                dc.drawCircle(cx, cy, star[:ringR] + (i * 3));
            }

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        }
        private function drawSecMercury(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.15;
            var bodyR = radius * 0.07;

            // Second position
            var angle = (s.sec * 2.0 * Math.PI / 60) - (Math.PI / 2.0);

            // Body Position
            var mx = cx + (orbitR * Math.cos(angle));
            var my = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, bodyR);

            // Text
            var t = s.sec.toString();
            var tOffsetH = dc.getFontHeight(FONTS[:sec]) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - tOffsetH, FONTS[:sec], t, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawMinVenus(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.3;
            var bodyR = radius * 0.08;

            // Minute position
            var angle = (s.min * 2.0 * Math.PI / 60) - (Math.PI / 2.0);

            // Body Position
            var vx = cx + (orbitR * Math.cos(angle));
            var vy = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(vx, vy, bodyR);

            // Text
            var t = s.min.toString();
            var tOffset = dc.getFontHeight(FONTS[:min]) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(vx, vy - tOffset, FONTS[:min], t, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawHourTerra(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.45;
            var bodyR = radius * 0.08;

            var hour12 = s.hour % 12;
            var smoothHour = hour12 + (s.min / 60.0);

            // Hour Angle
            var angle = (smoothHour * 2.0 * Math.PI / 12) - (Math.PI / 2.0);

            // Body Position
            var tx = cx + (orbitR * Math.cos(angle));
            var ty = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(tx, ty, bodyR);

            // Text
            if (hour12 == 0) { hour12 = 12; }
            var t = System.getDeviceSettings().is24Hour ? s.hour : hour12;
            var tOffset = dc.getFontHeight(FONTS[:hour]) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(tx, ty - tOffset, FONTS[:hour], t, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawDayMars(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.6;
            var bodyR = radius * 0.08;

            // Day angle
            var day = s.day;
            var dowOffset = (s.hour / 24.0);

            // Smoothing
            var smoothDow = day.toFloat() + dowOffset.toFloat() - 1;
            var lastDayOfMonth = getLastDayOfMonth(dc, s);
            var angle = (smoothDow * 2.0 * Math.PI / lastDayOfMonth) - (Math.PI / 2.0);

            // Body Position
            var mx = cx + (orbitR * Math.cos(angle));
            var my = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, bodyR);

            // Text
            var t = s.day.toString();
            var tOffset = dc.getFontHeight(FONTS[:day]) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - tOffset, FONTS[:day], t, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawMonthJupiter(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.75;
            var bodyR = radius * 0.08;

            // Month Angle
            var mon = s.month;

            var lastDayOfMonth = getLastDayOfMonth(dc, s);
            var monOffset = s.day.toFloat() / lastDayOfMonth.toFloat();
            var smoothMon = mon + monOffset - 1;

            var angle = (smoothMon * 2.0 * Math.PI / 12.0) - (Math.PI / 2.0);

            // Body Position
            var jx = cx + (orbitR * Math.cos(angle));
            var jy = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(jx, jy, bodyR);

            // Text
            // var rn = [null, "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII" ];
            var t = s.month.toString();
            // var t = rn[mon];
            var tOffset = dc.getFontHeight(FONTS[:mon]) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(jx, jy - tOffset, FONTS[:mon], t, Gfx.TEXT_JUSTIFY_CENTER);
        }

        // DOW HIGHLIGHT
        private function drawDowHighlight(dc as Dc, s as Planetary.State) {
            var dow = s.dow;
            var dies = [null, "SOLIS", "LUNAE", "MARTIS", "MERCURII", "IOVIS", "VENERIS", "SATURNI"];
            var t = dies[dow];

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - radius * 0.9, Gfx.FONT_XTINY, t, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
}