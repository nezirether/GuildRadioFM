# UI.6 readability and layout changes

## Typography and contrast

Page-level Settings heading is 24 logical units, group headings 20, Settings labels 18, descriptions 14 and text buttons 16. Other text uses a minimum of 13. Primary library/playlist/request track titles use 18. Secondary colors are light gray on a dark content backing. Existing skin accents and decorative artwork remain.

Large title text retains its original role, while additional space is provided through row height and scroll capacity. Long Settings descriptions can wrap within their own 30-unit description area. Search fields use 16-unit input text and 32-unit height.

## Settings

A single scrollable column groups Playback, Audio, Live Radio, Interface and Notifications. Each toggle row is 70 units tall with a ten-unit gap, label and description bounds ending before the 76 by 32 toggle. The viewport clips the scrolling child. Mouse wheel and explicit Scroll up/down buttons provide navigation.

The ten original preferences and their existing callbacks remain. Volume, interface size and background choices remain in the corresponding groups. SavedVariables names are preserved.

## Controls and other pages

Secondary buttons and icons use plain surfaces. Major framing remains at the window, header and deliberate panels. The main Play button is a clear glyph on a contrasting surface after live inspection identified the decorative frame as an obstruction.

Lists use at least 34-unit rows, with visible rows computed from the viewport height. Library and playlist track labels are enlarged. Live's request-search area begins below the larger pills. Footer notes are constrained to their column and shortened where necessary.

## Mini-player

Dimensions are 560 by 86 logical units. The title is 20, status 14 and time labels 13. There is a five-unit progress line with separate elapsed and duration labels. Previous/next and Play retain their existing callbacks and distinct hit areas. The mini-player continues to use the simple isolated border and dark backing from UI.5.

## Evidence

The installed addon UI was backed up before testing. UI files were copied into the existing installation for the client tour. Frozen engine files were verified before installation. Actual client captures include the original overcrowded Settings page and the repaired grouped version.

Final screenshots and the verification report distinguish observed client results from automated checks and remaining limitations.
