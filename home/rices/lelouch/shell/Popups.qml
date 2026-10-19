import QtQuick
import Quickshell
import Quickshell.Io

// Everything that drops down from the bar, plus the scratchpad. One at a time (see Ui.popup).
Scope {
    DropPanel {
        name: "calendar"
        place: "center"
        cardWidth: 692
        page: Component { AgendaPage {} }
    }

    DropPanel {
        name: "media"
        place: "left"
        cardWidth: 460
        page: Component { MediaPage {} }
    }

    DropPanel {
        name: "layout"
        place: "left"
        cardWidth: 420
        page: Component { LayoutPage {} }
    }

    DropPanel {
        name: "alerts"
        place: "right"
        cardWidth: 460
        page: Component { AlertsPage {} }
    }

    DropPanel {
        name: "focus"
        place: "right"
        cardWidth: 460
        page: Component { FocusPage {} }
    }

    Scratchpad {}

    // Super+Y
    IpcHandler {
        target: "tiling"

        function cycle(): void {
            Tiling.cycle();
        }
    }

    Connections {
        target: Ui

        function onPopupChanged() {
            if (Ui.popup === "alerts")
                History.markRead();
        }
    }
}
