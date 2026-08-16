# ⏱️ SecondsClock

Adds **seconds** to the iOS status-bar clock, ticking live every second
(e.g. `3:45:12` instead of `3:45`). Respects your 12h/24h setting.

## Requirements
- Jailbroken iPhone, rootless (Dopamine / ElleKit), iOS 15–17

## How it works
Hooks `SBStatusBarStateAggregator`:
- `_resetTimeItemFormatter` → injects `:ss` into the time `NSDateFormatter`(s)
- `_restartTimeItemTimer` → replaces the stock minute-aligned timer with a
  1-second repeating timer so the seconds update live

## Install
Prebuilt package: `releases/SecondsClock_1.0.0.deb` — open it in **Sileo** → Install → Respring.

## Build
`export THEOS=~/theos && make package FINALPACKAGE=1`

## Uninstall
`dpkg -r com.custom.secondsclock && killall SpringBoard` (or remove in Sileo).
