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
            :mercury => 0.15, :venus => 0.30, :terra => 0.45,
            :mars => 0.60, :jupiter => 0.75, :saturn => 0.90
        };
        private const BODY_COLOR = {
            :mercury => Gfx.COLOR_LT_GRAY, :venus => Gfx.COLOR_ORANGE, :terra => Gfx.COLOR_GREEN,
            :mars => Gfx.COLOR_RED, :jupiter => Gfx.COLOR_ORANGE, :saturn => Gfx.COLOR_YELLOW
        };
        private const FONTS = {
            :sec => Gfx.FONT_XTINY, :min => Gfx.FONT_XTINY, :hour => Gfx.FONT_XTINY,
            :day => Gfx.FONT_XTINY, :mon => Gfx.FONT_XTINY, :year => Gfx.FONT_XTINY
        };

        private function orbitPos(orbitR as Float, smoothed as Float, period as Number) as Array {
            var angle = (smoothed * 2.0 * Math.PI / period) - (Math.PI / 2.0);
            return [
                cx + (orbitR * Math.cos(angle)),
                cy + (orbitR * Math.sin(angle))
            ] as Array;
        }
        private function smoothed(whole as Float, fraction as Float, total as Float) as Float {
            return whole + (fraction / total);
        }
        private function drawBody(dc as Dc, x, y, bodyR, color as Number) {
            dc.setColor(color, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, bodyR);
        }
        private function drawBodyText(dc as Dc, x, y, font, t as String) {
            var tOffset = dc.getFontHeight(font) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(x, y - tOffset, font, t, Gfx.TEXT_JUSTIFY_CENTER);
        }

        private function starStyleForBattery(batt as Number, baseR as Number) as Dictionary {
            var coreR, ringR, color, ringColor; 
            var ringCount = 1;

            if (batt > 75) { 
                coreR = baseR; ringR = baseR * 1.3;
                color = Gfx.COLOR_YELLOW; ringColor = Gfx.COLOR_WHITE;
            }
            else if (batt > 50){ 
                coreR = baseR * 1.3; ringR = baseR * 1.7; 
                color = Gfx.COLOR_RED; ringColor = Gfx.COLOR_ORANGE;
            }
            else if (batt > 40) { 
                coreR = baseR * 0.9; ringR = baseR * 2.0;
                ringCount = 2;
                color = Gfx.COLOR_WHITE; ringColor = Gfx.COLOR_YELLOW;
            }
            else if (batt > 15){ 
                coreR = baseR * 0.6; ringR = baseR * 0.9;
                color = Gfx.COLOR_BLUE; ringColor = Gfx.COLOR_WHITE;
            }
            else { 
                coreR = baseR * 0.3; ringR = baseR * 0.6;
                color = Gfx.COLOR_BLACK; ringColor = Gfx.COLOR_DK_GRAY;
            }

            return {
                :coreR => coreR, :ringR => ringR,
                :ringCount => ringCount,
                :color => color, :ringColor => ringColor
            };
        }
        private function getLastDayOfMonth(dc as Dc, s as Planetary.State) {
            var nextMonth = s.month + 1;
            var year = s.year;
            if (nextMonth > 12) {
                nextMonth = 1;
                year++;
            }
            var options = {
                :year => year, :month => nextMonth, :day => 1,
                :hour => s.hour, :minute => s.min, :second => s.sec
            };

            var when = Time.Gregorian.moment(options);
            var oneDay = new Time.Duration(Time.Gregorian.SECONDS_PER_DAY);
            when = when.subtract(oneDay);

            var info = Time.Gregorian.utcInfo(when, Time.FORMAT_SHORT);
            return info.day;
        }
        private function toRomanNumeral(n as Number) as String {
            var values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
            var symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];

            var result = "";
            for (var i = 0; i < values.size(); i++) {
                while (n >= values[i]) {
                    result += symbols[i];
                    n -= values[i];
                }
            }
            return result;
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

            // Background
            drawTimeSeparationLine(dc);

            // Status indicators
            drawBatterySol(dc, s);

            // Time
            drawSecMercury(dc, s);
            drawMinVenus(dc, s);
            drawHourTerra(dc, s);

            // Date
            drawYearSaturn(dc, s);
            drawMonthJupiter(dc, s);
            drawDayMars(dc, s);

            // Labels
            drawDowLabel(dc, s);
            drawMonthLabel(dc, s);
            // drawYearLabel(dc, s);
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
            var pos = orbitPos(radius * ORBITS[:mercury], s.sec.toFloat(), 60);
            var bodyR = radius * 0.07;

            var t = s.sec.toString();
            if (t.length() == 1) { t = "0" + t; }

            drawBody(dc, pos[0], pos[1], bodyR, BODY_COLOR[:mercury]);
            drawBodyText(dc, pos[0], pos[1], FONTS[:sec], t);
        }
        private function drawMinVenus(dc as Dc, s as Planetary.State) {
            var pos = orbitPos(radius * ORBITS[:venus], smoothed(s.min.toFloat(), s.sec.toFloat(), 60.0), 60);
            var bodyR = radius * 0.08;

            var t = s.min.toString();
            if (t.length() == 1) { t = "0" + t; }

            drawBody(dc, pos[0], pos[1], bodyR, BODY_COLOR[:venus]);
            drawBodyText(dc, pos[0], pos[1], FONTS[:min], t);
        }
        private function drawHourTerra(dc as Dc, s as Planetary.State) {
            var hour12 = (s.hour % 12).toFloat();
            var pos = orbitPos(radius * ORBITS[:terra], smoothed(hour12, s.min.toFloat(), 60.0), 12);
            var bodyR = radius * 0.08;

            var t = s.hour.toString();

            drawBody(dc, pos[0], pos[1], bodyR, BODY_COLOR[:terra]);
            drawBodyText(dc, pos[0], pos[1], FONTS[:hour], t);
        }
        private function drawDayMars(dc as Dc, s as Planetary.State) {
            var lastDayOfMonth = getLastDayOfMonth(dc, s);
            var pos = orbitPos(radius * ORBITS[:mars], smoothed(s.day.toFloat() - 1, s.hour.toFloat(), 24.0), lastDayOfMonth);
            var bodyR = radius * 0.08;

            var t = s.day.toString();

            drawBody(dc, pos[0], pos[1], bodyR, BODY_COLOR[:mars]);
            drawBodyText(dc, pos[0], pos[1], FONTS[:day], t);
        }
        private function drawMonthJupiter(dc as Dc, s as Planetary.State) {
            var lastDay = getLastDayOfMonth(dc, s).toFloat();
            var pos = orbitPos(radius * ORBITS[:jupiter], smoothed(s.month - 1.toFloat(), s.day.toFloat(), lastDay), 12);
            var bodyR = radius * 0.08;

            var t = s.month.toString();

            drawBody(dc, pos[0], pos[1], bodyR, BODY_COLOR[:jupiter]);
            drawBodyText(dc, pos[0], pos[1], FONTS[:mon], t);
        }
        private function drawYearSaturn(dc as Dc, s as Planetary.State) {
            var pos = orbitPos(radius * ORBITS[:saturn], s.year.toFloat(), 100);
            var bodyR = radius * 0.08;

            dc.setColor(BODY_COLOR[:saturn], Gfx.COLOR_TRANSPARENT);
            dc.drawEllipse(pos[0], pos[1], (bodyR * 2.4).toNumber(), (bodyR * 0.6).toNumber());
            drawBody(dc, pos[0], pos[1], bodyR, BODY_COLOR[:saturn]);

            var yearString = s.year.toString();
            var t = yearString.substring(yearString.length() - 2, yearString.length());
            
            drawBodyText(dc, pos[0], pos[1], FONTS[:year], t);
        }

        // DOW HIGHLIGHT
        private function drawDowLabel(dc as Dc, s as Planetary.State) {
            var dow = s.dow;
            var dies = [null, "SOLIS", "LUNAE", "MARTIS", "MERCURII", "IOVIS", "VENERIS", "SATURNI"];
            var t = dies[dow];

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - radius * 0.88, Gfx.FONT_XTINY, t, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawMonthLabel(dc as Dc, s as Planetary.State) {
            var t = toRomanNumeral(s.month.toNumber());
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - radius * 0.98, Gfx.FONT_XTINY, t, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawYearLabel(dc as Dc, s as Planetary.State) {
            var t = toRomanNumeral(s.year.toNumber());
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + radius * 0.85, Gfx.FONT_XTINY, t, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
}