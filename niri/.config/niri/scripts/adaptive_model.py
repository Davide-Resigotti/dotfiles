#!/usr/bin/env python3
"""
Lightweight Dual-Profile Kernel Anchor Spline for Adaptive Brightness
Learns personalized screen brightness curves separately for AC Power and Battery operation:
- Battery Profile: Power-saving curve calibrated to a 30% baseline in typical lighting (~485 lux).
- AC Power Profile: Vibrant high-quality curve calibrated to a 55% baseline in typical lighting.
- Training Window: Active learning for a configurable period (default: 7 days) with countdown tracking.
- Zero external dependencies (pure Python standard library).
"""

import json
import math
import os
import time

STATE_DIR = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
MODEL_FILE = os.path.join(STATE_DIR, "brightness_model.json")


class AdaptiveBrightnessModel:
    # Battery Anchors: Optimized for maximum power conservation (30% at ~485 lux)
    DEFAULT_BATTERY_ANCHORS = [
        (0.0, 2.0),       # Pitch black (comfortable dim minimum ~10 nits)
        (5.0, 5.0),       # Very dark
        (20.0, 10.0),     # Dim candle / night light
        (50.0, 18.0),     # Dim indoor
        (150.0, 22.0),    # Normal indoor
        (485.0, 30.0),    # Baseline room lighting (~485 lux -> 30%)
        (1500.0, 45.0),   # Very bright indoor / sunlit room
        (5000.0, 70.0),   # Overcast outdoor
        (10000.0, 90.0),  # Direct sunlight
    ]

    # AC Power Anchors: Optimized for visual comfort, vibrancy, and readability (55% at ~485 lux)
    DEFAULT_AC_ANCHORS = [
        (0.0, 10.0),      # Pitch black (comfortable minimum)
        (5.0, 15.0),      # Very dark
        (20.0, 25.0),     # Dim candle / night light
        (50.0, 35.0),     # Dim indoor
        (150.0, 45.0),    # Normal indoor
        (485.0, 55.0),    # Bright room lighting (~485 lux -> 55% vibrant display)
        (1500.0, 75.0),   # Very bright indoor / near window
        (5000.0, 90.0),   # Overcast outdoor
        (10000.0, 100.0), # Direct sunlight
    ]

    SIGMA = 0.55  # Radius of influence in log10 space (~0.55 orders of magnitude)

    def __init__(self, filepath=MODEL_FILE):
        self.filepath = filepath
        self.profiles = {
            "battery": {
                "anchors": [list(a) for a in self.DEFAULT_BATTERY_ANCHORS],
                "observations": [],
            },
            "ac": {
                "anchors": [list(a) for a in self.DEFAULT_AC_ANCHORS],
                "observations": [],
            },
        }
        self.training = {
            "enabled": True,
            "start_time": time.time(),
            "duration_days": 7,
        }
        self.load()

    @staticmethod
    def _log_x(lux):
        return math.log10(max(0.0, float(lux)) + 1.0)

    # --- Training Window Management ---
    def is_training_active(self):
        """Returns True if training mode is currently enabled and within duration."""
        if not self.training.get("enabled", True):
            return False
        start = self.training.get("start_time")
        if start is None:
            return True
        days = self.training.get("duration_days", 7)
        return (time.time() - start) < (days * 86400)

    def get_training_time_left(self):
        """Returns (days_left, hours_left, is_active)."""
        if not self.training.get("enabled", True):
            return 0, 0, False
        start = self.training.get("start_time")
        if start is None:
            return 7, 0, True
        days = self.training.get("duration_days", 7)
        seconds_left = max(0.0, (start + days * 86400) - time.time())
        if seconds_left <= 0:
            return 0, 0, False
        days_left = int(seconds_left // 86400)
        hours_left = int((seconds_left % 86400) // 3600)
        return days_left, hours_left, True

    def toggle_training(self):
        """Toggles training mode on/off. If re-enabling an expired session, resets timer."""
        was_active = self.is_training_active()
        if was_active:
            self.training["enabled"] = False
        else:
            self.training["enabled"] = True
            self.training["start_time"] = time.time()
        self.save()
        return self.training["enabled"]

    def set_training_duration(self, days=7):
        """Sets training duration in days and starts/resets the training window."""
        days = max(1, int(days))
        self.training["duration_days"] = days
        self.training["start_time"] = time.time()
        self.training["enabled"] = True
        self.save()

    # --- Prediction & Learning ---
    def learn(self, lux, target_pct, profile="battery", learning_rate=0.75):
        """
        Learns from a manual user adjustment on a specific power profile ('battery' or 'ac').
        Adjusts local anchors via Gaussian kernel weighting in log space.
        """
        if not self.is_training_active():
            return

        profile = profile if profile in self.profiles else "battery"
        p_data = self.profiles[profile]

        target_pct = max(1.0, min(100.0, float(target_pct)))
        lux = max(0.0, float(lux))
        p_data["observations"].append([round(lux, 1), round(target_pct, 1)])
        if len(p_data["observations"]) > 50:
            p_data["observations"] = p_data["observations"][-50:]

        user_x = self._log_x(lux)
        default_anchors = (
            self.DEFAULT_BATTERY_ANCHORS if profile == "battery" else self.DEFAULT_AC_ANCHORS
        )

        for idx, (a_lux, _) in enumerate(default_anchors):
            a_x = self._log_x(a_lux)
            dist_sq = (a_x - user_x) ** 2
            # Gaussian kernel weight
            kernel_weight = math.exp(-dist_sq / (2.0 * (self.SIGMA ** 2)))
            lr = learning_rate * kernel_weight

            current_val = p_data["anchors"][idx][1]
            new_val = (1.0 - lr) * current_val + lr * target_pct
            p_data["anchors"][idx][1] = round(max(1.0, min(100.0, new_val)), 2)

        # Enforce strict monotonicity across anchors
        for i in range(1, len(p_data["anchors"])):
            if p_data["anchors"][i][1] < p_data["anchors"][i - 1][1]:
                p_data["anchors"][i][1] = p_data["anchors"][i - 1][1]

        self.save()

    def predict(self, lux, profile="battery"):
        """
        Interpolates the target screen percentage for a given lux reading and power profile.
        Returns continuous float percentage (e.g. 30.0 on battery, 55.0 on AC).
        """
        profile = profile if profile in self.profiles else "battery"
        anchors = self.profiles[profile]["anchors"]

        if lux is None:
            return 30.0 if profile == "battery" else 55.0

        lux = max(0.0, float(lux))
        if lux <= anchors[0][0]:
            return anchors[0][1]
        if lux >= anchors[-1][0]:
            return anchors[-1][1]

        target_x = self._log_x(lux)
        for i in range(len(anchors) - 1):
            l0, v0 = anchors[i]
            l1, v1 = anchors[i + 1]
            if l0 <= lux <= l1:
                x0, x1 = self._log_x(l0), self._log_x(l1)
                t = (target_x - x0) / (x1 - x0) if x1 > x0 else 0.0
                val = v0 + t * (v1 - v0)
                return max(1.0, min(100.0, val))

        return 30.0 if profile == "battery" else 55.0

    def reset(self, profile=None):
        """Resets specified profile ('battery', 'ac') or both to factory defaults."""
        if profile in ("battery", None):
            self.profiles["battery"] = {
                "anchors": [list(a) for a in self.DEFAULT_BATTERY_ANCHORS],
                "observations": [],
            }
        if profile in ("ac", None):
            self.profiles["ac"] = {
                "anchors": [list(a) for a in self.DEFAULT_AC_ANCHORS],
                "observations": [],
            }
        self.save()

    def save(self):
        try:
            os.makedirs(os.path.dirname(self.filepath), exist_ok=True)
            payload = {
                "version": 2,
                "profiles": self.profiles,
                "training": self.training,
            }
            with open(self.filepath, "w") as f:
                json.dump(payload, f, indent=2)
        except Exception:
            pass

    def load(self):
        if not os.path.isfile(self.filepath):
            return

        try:
            with open(self.filepath, "r") as f:
                data = json.load(f)

            if "profiles" in data:
                # Modern schema (v2)
                for prof in ("battery", "ac"):
                    if prof in data["profiles"]:
                        if "anchors" in data["profiles"][prof]:
                            self.profiles[prof]["anchors"] = data["profiles"][prof]["anchors"]
                        if "observations" in data["profiles"][prof]:
                            self.profiles[prof]["observations"] = data["profiles"][prof][
                                "observations"
                            ]
                if "training" in data:
                    self.training.update(data["training"])
            elif "anchors" in data:
                # Migration from v1 single-profile: preserve user battery learning
                self.profiles["battery"]["anchors"] = data["anchors"]
                if "observations" in data:
                    self.profiles["battery"]["observations"] = data["observations"]
                # Save migrated version
                self.save()
        except Exception:
            pass


if __name__ == "__main__":
    import sys

    model = AdaptiveBrightnessModel()
    if len(sys.argv) > 1 and sys.argv[1] == "reset":
        target = sys.argv[2] if len(sys.argv) > 2 else None
        model.reset(target)
        print(f"Adaptive brightness model reset ({target or 'all profiles'}).")
    else:
        days, hours, active = model.get_training_time_left()
        print("=== Adaptive Brightness Machine Learning Model ===")
        print(f"Training Status: {'ACTIVE (' + str(days) + 'd ' + str(hours) + 'h left)' if active else 'LOCKED (Training Completed)'}")
        for prof in ("battery", "ac"):
            p_name = "Battery Profile (Power Saver)" if prof == "battery" else "AC Power Profile (Best Experience)"
            print(f"\n--- {p_name} ---")
            print(f"Observations: {len(model.profiles[prof]['observations'])}")
            for lux, pct in model.profiles[prof]["anchors"]:
                print(f"  {lux:7.1f} lux  -->  {pct:5.1f}%")
