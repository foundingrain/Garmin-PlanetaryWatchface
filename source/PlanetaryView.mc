import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Planetary;

class PlanetaryView extends WatchUi.WatchFace {
    private var state as Planetary.State;
    private var draw as Planetary.Renderer;
    
    function initialize() {
        WatchFace.initialize();
        state = new Planetary.State();
        draw = new Planetary.Renderer();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        draw.setDimensions(dc);
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        state.updateFast();
        state.updateSlow();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        state.updateFast();
        if (state.shouldRunSlow(15)) {
            state.updateSlow();
        }

        draw.render(dc, state);

        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
