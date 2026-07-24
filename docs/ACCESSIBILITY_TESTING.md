# Testing Shadow with TalkBack (Android screen reader)

TalkBack is Android's built-in screen reader — the primary tool blind and
low-vision students use. Mode 2 (visual assistance) exists for exactly these
users, so it must be fully operable with the screen turned off.

## Turn TalkBack on

- **Settings → Accessibility → TalkBack → toggle On.** Confirm the prompt.
- Shortcut to toggle quickly: **hold both volume keys** for 3 seconds (enable this
  shortcut once under Settings → Accessibility → TalkBack → TalkBack shortcut).
- First time, Android offers a short tutorial — worth doing once.

## The gestures you need

| Gesture | Does |
|---|---|
| **Swipe right / left** | Move to next / previous element (it reads aloud) |
| **Double-tap anywhere** | Activate the focused element (like a normal tap) |
| **Two-finger swipe** | Scroll |
| **Swipe up-then-right** | Open TalkBack global menu (to pause/stop) |

Key idea: you **navigate** by swiping (one element at a time) and **activate** by
double-tapping. You do not tap directly.

## What to check on each screen

Put the phone down or close your eyes and drive the whole app by ear.

1. **Home (welcome):** swipe through the four cards. Each should announce its
   Arabic name and description and say **"زر" (button)**, e.g. "صمم / ضعف سمع،
   ترجمة فورية للمحاضرات، زر". Double-tap opens the mode. Nothing should be
   silent or read twice.
2. **Every screen — back button:** the first element should announce **"رجوع،
   زر"** and double-tap should go back.
3. **Visual assistance (the critical one):**
   - "صف المحيط" and "اقرأ النص" each announce as buttons and open the camera on
     double-tap.
   - After analysis, the Arabic result should be **spoken automatically** when it
     appears (it is marked as a live region). If TalkBack stays silent when the
     result appears, that is a bug — tell me.
   - "استمع للنتيجة" announces and plays the spoken result.
4. **Deaf mode:** the record button announces **"بدء التسجيل، زر"**, and after you
   start it announces **"إيقاف التسجيل"**. حفظ / مسح / نسخ each announce their name
   and "زر".
5. **Learning support:** "اختر ملفاً" and تلخيص / تبسيط / أسئلة مراجعة announce and
   activate; the AI result is spoken when it appears.
6. **Voice control:** the big mic announces "اضغط وتكلم لإعطاء أمر صوتي، زر"; the
   recognised command is spoken when it comes back.

## Touch-target size (for motor impairment)

Every button should be at least **48×48 dp**. The nav/action icon buttons were
raised from 40 to 48 dp; the large mode cards, camera buttons, and mic buttons are
well above the minimum. If any control feels hard to hit, note which one.

## Reporting back

For anything that reads wrong, silent, doubled, or won't activate, tell me the
**screen** and the **element** (e.g. "visual assistance, the listen button reads
nothing"). That's enough for me to fix it.

## Quick option without a device

Android Studio's emulator supports TalkBack (install it via the emulator's Play
Store, or it's preinstalled on most system images). A physical device is more
representative, especially for the camera in mode 2.
