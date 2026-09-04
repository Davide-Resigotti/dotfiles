#!/usr/bin/env python3
"""
Lightweight Kernel Anchor Spline for Adaptive Brightness
Learns personalized screen brightness curves from manual adjustments.
- Zero external dependencies (pure Python standard library)
- Logarithmic-space kernel regression matching human perception
- Guaranteed monotonicity (brighter room never produces dimmer screen)
"""

import json
import math
import os

STATE_DIR = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
MODEL_FILE = os.path.join(STATE_DIR, "brightness_model.json")


class AdaptiveBrightnessModel:
    # Default anchors calibrated to give a 30% baseline in typical room light (~485 lux)
    DEFAULT_ANCHORS = [
        (0.0, 5.0),       # Pitch black
        (5.0, 10.0),      # Very dark
        (20.0, 15.0),     # Dim candle / night light
        (50.0, 20.0),     # Dim indoor
        (150.0, 22.0),    # Normal indoor
        (485.0, 30.0),    # Baseline room lighting (~485 lux -> 30%)
        (1500.0, 45.0),   # Very bright indoor / sunlit room
        (5000.0, 70.0),   # Overcast outdoor
        (10000.0, 90.0),  # Direct sunlight
    ]
    SIGMA = 0.55  # Radius of influence in log10 space (~0.55 orders of magnitude)

    def __init__(self, filepath=MODEL_FILE):
        self.filepath = filepath
        self.observations = []  # [[lux, target_pct, timestamp], ...]
        self.anchors = [list(a) for a in self.DEFAULT_ANCHORS]
        self.load()

    @staticmethod
    def _log_x(lux):
        return math.log10(max(0.0, float(lux)) + 1.0)

    def learn(self, lux, target_pct, learning_rate=0.75):
        """
        Learns from a user manual adjustment (lux -> target_pct).
        Adjusts local anchors via Gaussian kernel weighting in log space.
        """
        target_pct = max(5.0, min(100.0, float(target_pct)))
        lux = max(0.0, float(lux))
        self.observations.append([round(lux, 1), round(target_pct, 1)])
        if len(self.observations) > 50:
            self.observations = self.observations[-50:]

        user_x = self._log_x(lux)

        for idx, (a_lux, _) in enumerate(self.DEFAULT_ANCHORS):
            a_x = self._log_x(a_lux)
            dist_sq = (a_x - user_x) ** 2
            # Gaussian kernel weight
            kernel_weight = math.exp(-dist_sq / (2.0 * (self.SIGMA ** 2)))
            lr = learning_rate * kernel_weight

            current_val = self.anchors[idx][1]
            new_val = (1.0 - lr) * current_val + lr * target_pct
            self.anchors[idx][1] = round(max(5.0, min(100.0, new_val)), 2)

        # Enforce strict monotonicity across anchors
        for i in range(1, len(self.anchors)):
            if self.anchors[i][1] < self.anchors[i - 1][1]:
                self.anchors[i][1] = self.anchors[i - 1][1]

        self.save()

    def predict(self, lux):
        """
        Interpolates the target screen percentage for a given lux reading.
        Returns continuous float percentage (e.g. 30.2).
        """
        if lux is None:
            return 30.0

        lux = max(0.0, float(lux))
        if lux <= self.anchors[0][0]:
            return self.anchors[0][1]
        if lux >= self.anchors[-1][0]:
            return self.anchors[-1][1]

        target_x = self._log_x(lux)
        for i in range(len(self.anchors) - 1):
            l0, v0 = self.anchors[i]
            l1, v1 = self.anchors[i + 1]
            if l0 <= lux <= l1:
                x0, x1 = self._log_x(l0), self._log_x(l1)
                t = (target_x - x0) / (x1 - x0) if x1 > x0 else 0.0
                val = v0 + t * (v1 - v0)
                return max(5.0, min(100.0, val))

        return 30.0

    def reset(self):
        """Resets the model to factory default curve."""
        self.observations = []
        self.anchors = [list(a) for a in self.DEFAULT_ANCHORS]
        if os.path.exists(self.filepath):
            try:
                os.remove(self.filepath)
            except OSError:
                pass
        self.save()

    def save(self):
        try:
            os.makedirs(os.path.dirname(self.filepath), exist_ok=True)
            with open(self.filepath, "w") as f:
                json.dump({"anchors": self.anchors, "observations": self.observations}, f, indent=2)
        except Exception:
            pass

    def load(self):
        if os.path.isfile(self.filepath):
            try:
                with open(self.filepath, "r") as f:
                    data = json.load(f)
                    if "anchors" in data:
                        self.anchors = data["anchors"]
                    if "observations" in data:
                        self.observations = data["observations"]
            except Exception:
                pass


if __name__ == "__main__":
    import sys
    model = AdaptiveBrightnessModel()
    if len(sys.argv) > 1 and sys.argv[1] == "reset":
        model.reset()
        print("Adaptive brightness model reset to defaults.")
    else:
        print("=== Adaptive Brightness Model Anchors ===")
        for lux, pct in model.anchors:
            print(f"  {lux:7.1f} lux -> {pct:5.1f}%")
        print(f"Learned observations count: {len(model.observations)}")
