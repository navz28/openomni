#!/usr/bin/env python3
"""
OpenOmni - pc_bridge.py
Puente PC para el HUB en modo Serial (ESP32 normal, sin USB HID nativo).
Lee lineas "LOC <x> <y> <run>" (x,y en -127..127) del hub por USB-serie
y crea un MANDO VIRTUAL que SteamVR/juegos ven como stick izquierdo.

Backends:
  - Windows: pip install vgamepad pyserial      (requiere driver ViGEmBus)
  - Linux:   pip install pyserial ; modulo uinput del kernel (sudo modprobe uinput)
             y permisos sobre /dev/uinput

Uso:
  python pc_bridge.py --port COM5           (Windows)
  python pc_bridge.py --port /dev/ttyUSB0   (Linux)

Si tu hub es un ESP32-S3 con USB HID (USE_USB_HID=1), NO necesitas esto:
el hub ya se ve como mando directamente.
"""
import argparse, sys, time

def clamp(v, lo, hi):
    return lo if v < lo else hi if v > hi else v

# ----------------------------------------------------------------
class WinPad:
    """Mando virtual Xbox 360 via vgamepad (ViGEm)."""
    def __init__(self):
        import vgamepad as vg
        self.vg = vg
        self.pad = vg.VX360Gamepad()

    def update(self, x, y, run):
        # x,y en -127..127 ; vgamepad espera float -1..1 (Y arriba = +)
        self.pad.left_joystick_float(x_value_float=clamp(x/127.0, -1, 1),
                                     y_value_float=clamp(-y/127.0, -1, 1))
        btn = self.vg.XUSB_BUTTON.XUSB_GAMEPAD_A
        (self.pad.press_button if run else self.pad.release_button)(button=btn)
        self.pad.update()

# ----------------------------------------------------------------
class LinuxPad:
    """Mando virtual via python-uinput."""
    def __init__(self):
        import uinput
        self.uinput = uinput
        self.events = (
            uinput.ABS_X + (-127, 127, 0, 0),
            uinput.ABS_Y + (-127, 127, 0, 0),
            uinput.BTN_A,
        )
        self.dev = uinput.Device(self.events, name="OpenOmni Treadmill")
        time.sleep(0.3)

    def update(self, x, y, run):
        self.dev.emit(self.uinput.ABS_X, int(clamp(x, -127, 127)), syn=False)
        self.dev.emit(self.uinput.ABS_Y, int(clamp(y, -127, 127)), syn=False)
        self.dev.emit(self.uinput.BTN_A, 1 if run else 0)

# ----------------------------------------------------------------
def make_pad():
    if sys.platform.startswith("win"):
        return WinPad()
    return LinuxPad()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", required=True, help="puerto serie del hub (COMx o /dev/ttyUSBx)")
    ap.add_argument("--baud", type=int, default=115200)
    args = ap.parse_args()

    import serial  # pyserial
    ser = serial.Serial(args.port, args.baud, timeout=1)
    pad = make_pad()
    print(f"[OpenOmni] puente activo en {args.port}. Ctrl+C para salir.")

    last = time.time()
    while True:
        line = ser.readline().decode(errors="ignore").strip()
        if not line.startswith("LOC"):
            # watchdog: sin datos 0.3 s -> centra el stick
            if time.time() - last > 0.3:
                pad.update(0, 0, 0)
            continue
        try:
            _, xs, ys, rs = line.split()
            pad.update(int(xs), int(ys), int(rs))
            last = time.time()
        except ValueError:
            pass

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[OpenOmni] fin.")
