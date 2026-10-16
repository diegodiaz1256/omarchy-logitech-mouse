import importlib.machinery
import importlib.util
import os
import unittest

path = os.path.join(os.path.dirname(__file__), "..", "bin", "mouse-battery")
loader = importlib.machinery.SourceFileLoader("mouse_battery", path)
spec = importlib.util.spec_from_loader("mouse_battery", loader)
mb = importlib.util.module_from_spec(spec)
loader.exec_module(mb)

SAMPLE = """rules cannot access modifier keys in Wayland
solaar version 1.1.20

G502 X PLUS
     Device path  : /dev/hidraw3
     Kind         : mouse
         6: UNIFIED BATTERY        {1004} V3
            Battery: 77%, BatteryStatus.RECHARGING.
     Battery: 77%, BatteryStatus.RECHARGING.
"""


class Parse(unittest.TestCase):
    def test_percent_and_charging(self):
        r = mb.parse(SAMPLE)
        self.assertEqual((r["name"], r["percent"], r["charging"], r["status"]),
                         ("G502 X PLUS", 77, True, "recharging"))

    def test_through_receiver(self):
        r = mb.parse("solaar version 1.1.20\n\n  1: G502 X PLUS\n     Kind : mouse\n"
                     "         6: UNIFIED BATTERY {1004} V3\n            Battery: 98%, BatteryStatus.DISCHARGING.\n")
        self.assertEqual((r["name"], r["percent"], r["charging"]), ("G502 X PLUS", 98, False))

    def test_discharging(self):
        r = mb.parse("G502\n  Battery: 40%, BatteryStatus.DISCHARGING.\n")
        self.assertEqual((r["percent"], r["charging"]), (40, False))

    def test_level_only(self):
        r = mb.parse("G502\n  Battery: Good, BatteryStatus.DISCHARGING.\n")
        self.assertEqual((r["percent"], r["level"]), (70, "good"))

    def test_offline_has_no_percent(self):
        r = mb.parse("G502 X PLUS\n  Device path : x\n")
        self.assertIsNone(r["percent"])
        self.assertEqual(r["name"], "G502 X PLUS")


class Notify(unittest.TestCase):
    def reading(self, pct, charging=False):
        return {"percent": pct, "charging": charging}

    def test_once_per_episode(self):
        s = {}
        self.assertTrue(mb.decide_notify(s, self.reading(15), 15))
        self.assertFalse(mb.decide_notify(s, self.reading(14), 15))
        self.assertFalse(mb.decide_notify(s, self.reading(18), 15))   # inside hysteresis
        self.assertFalse(mb.decide_notify(s, self.reading(25), 15))   # re-armed
        self.assertTrue(mb.decide_notify(s, self.reading(12), 15))

    def test_charging_rearms_and_never_notifies(self):
        s = {"low_notified": True}
        self.assertFalse(mb.decide_notify(s, self.reading(10, True), 15))
        self.assertFalse(s["low_notified"])

    def test_disabled(self):
        self.assertFalse(mb.decide_notify({}, self.reading(1), 0))


if __name__ == "__main__":
    unittest.main()
