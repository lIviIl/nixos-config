import datetime
import json
import sys

import icalendar
import recurring_ical_events


def main():
    start = datetime.date.fromisoformat(sys.argv[1])
    end = datetime.date.fromisoformat(sys.argv[2])
    calendar = icalendar.Calendar.from_ical(sys.stdin.buffer.read())

    out = []
    for event in recurring_ical_events.of(calendar).between(start, end):
        begin = event.get("DTSTART").dt
        finish = event.get("DTEND")
        finish = finish.dt if finish is not None else None
        all_day = not isinstance(begin, datetime.datetime)

        if all_day:
            if finish is None:
                finish = begin + datetime.timedelta(days=1)
            first, last = begin, finish
        else:
            first = begin.astimezone()
            last = finish.astimezone() if isinstance(finish, datetime.datetime) else first

        out.append({
            "title": str(event.get("SUMMARY", "")),
            "location": str(event.get("LOCATION", "")),
            "allDay": all_day,
            "start": first.isoformat(),
            "end": last.isoformat(),
        })

    out.sort(key=lambda e: (e["start"][:10], not e["allDay"], e["start"]))
    print(json.dumps(out))


main()
