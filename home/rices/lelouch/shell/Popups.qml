import QtQuick
import Quickshell

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

    Connections {
        target: Ui

        function onPopupChanged() {
            if (Ui.popup === "alerts")
                History.markRead();
        }
    }
}
