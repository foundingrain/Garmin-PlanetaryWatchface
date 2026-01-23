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

        private const BG = Gfx.COLOR_BLACK;
        private const FG = Gfx.COLOR_WHITE;
        private const ALT = Gfx.COLOR_DK_GRAY;
        private const HL = Gfx.COLOR_YELLOW;
        private const SEC = Gfx.COLOR_RED;
        private const TR = Gfx.COLOR_TRANSPARENT;

        private const ORBITS = [ 0.15, 0.30, 0.45, 0.60, 0.75 ];

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
            dc.setColor(BG, BG);
            dc.clear();
        }

        public function render(dc as Dc, s as Planetary.State) {
            clear(dc);
            // drawDial(dc, s);
            drawOrbitalLines(dc);
            drawBatterySol(dc, s);
            drawSecMercury(dc, s);
            drawMinVenus(dc, s);
            drawHourTerra(dc, s);
            drawDayMars(dc, s);
            drawMonthJupiter(dc, s);
            //drawYearSaturn(dc, s);
        }
        public function drawDial(dc as Dc, s as Planetary.State) {
            var r = radius;

            dc.setColor(ALT, TR);

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
            var textOffset = dc.getFontHeight(Gfx.FONT_XTINY) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - textOffset, Gfx.FONT_XTINY, s.sec, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawMinVenus(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.3;
            var bodyR = radius * 0.08;

            // Minute position
            var angle = (s.min * 2.0 * Math.PI / 60) - (Math.PI / 2.0);

            // Body Position
            var mx = cx + (orbitR * Math.cos(angle));
            var my = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, bodyR);

            // Text
            var textOffset = dc.getFontHeight(Gfx.FONT_XTINY) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - textOffset, Gfx.FONT_XTINY, s.min, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawHourTerra(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.45;
            var bodyR = radius * 0.08;

            // Hour position
            var angle = ((s.hour % 12) * 2.0 * Math.PI / 12) - (Math.PI / 2.0);

            // Body Position
            var mx = cx + (orbitR * Math.cos(angle));
            var my = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, bodyR);

            // Text
            var hour = System.getDeviceSettings().is24Hour ? s.hour : s.hour % 12;
            var textOffset = dc.getFontHeight(Gfx.FONT_XTINY) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - textOffset, Gfx.FONT_XTINY, hour, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawDayMars(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.6;
            var bodyR = radius * 0.08;

            // Hour position
            var dow = s.dow - 1;
            var angle = (dow * 2.0 * Math.PI / 7.0) - (Math.PI / 2.0);

            // Body Position
            var mx = cx + (orbitR * Math.cos(angle));
            var my = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, bodyR);

            // Text
            var textOffset = dc.getFontHeight(Gfx.FONT_XTINY) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - textOffset, Gfx.FONT_XTINY, s.day, Gfx.TEXT_JUSTIFY_CENTER);
        }
        private function drawMonthJupiter(dc as Dc, s as Planetary.State) {
            var orbitR = radius * 0.75;
            var bodyR = radius * 0.08;

            // Hour position
            var mon = s.month;
            var angle = (mon * 2.0 * Math.PI / 12.0) - (Math.PI / 2.0);

            // Body Position
            var mx = cx + (orbitR * Math.cos(angle));
            var my = cy + (orbitR * Math.sin(angle));

            // Body
            dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, bodyR);

            // Text
            var textOffset = dc.getFontHeight(Gfx.FONT_XTINY) / 2;
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.drawText(mx, my - textOffset, Gfx.FONT_XTINY, s.month, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
}