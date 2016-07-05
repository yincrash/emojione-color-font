@ECHO OFF
SETLOCAL

SET MS_EMOJI_FONT_PATH="%SystemRoot%\Fonts\seguiemj.ttf"
SET MS_FONT_PATH="%SystemRoot%\Fonts\seguisym.ttf"
SET EMOJI_FONT_PATH="%CD%\EmojiOneColor-SVGinOT.ttf"
SET FINAL_EMJ_FONT_PATH_NO_QUOTES=%CD%\Segoe UI Emoji with EmojiOne.ttf
SET FINAL_EMJ_FONT_PATH="%FINAL_EMJ_FONT_PATH_NO_QUOTES%"
SET FINAL_FONT_PATH_NO_QUOTES=%CD%\Segoe UI Symbol with EmojiOne.ttf
SET FINAL_FONT_PATH="%FINAL_FONT_PATH_NO_QUOTES%"
SET CMAP_SCRIPT="%CD%\generate_cmap4_from_12.py"

ECHO Checking if Segoe UI Emoji is installed

REM Windows 8 uses Segoe UI Emoji in addition to Symbol
REM Windows 7 only uses Segoe UI Symbol
REM We have to replace _both_ 
ECHO Checking if Segoe UI Symbol is installed.

IF NOT EXIST %MS_FONT_PATH% (
    ECHO.
    ECHO You don't seem to have the Segoe UI Symbol Font installed.
    ECHO https://support.microsoft.com/en-us/kb/2729094
    GOTO :ERROR
)

ECHO Checking if prerequisites are installed.

WHERE python >nul 2>nul || (
    ECHO.
    ECHO Python not available in PATH. Is it installed?
    ECHO https://www.python.org/downloads/windows/
    GOTO :ERROR
)
WHERE pyftmerge >nul 2>nul || (
    ECHO.
    ECHO FontTools 3.x is not available in PATH. Is it installed?
    ECHO https://github.com/behdad/fonttools
    GOTO :ERROR
)

PUSHD %TEMP%
IF EXIST %MS_EMOJI_FONT_PATH% (
    ECHO Creating new Segoe UI Emoji font from EmojiOne
    ttx -t "name" -o "emjname.ttx" %MS_EMOJI_FONT_PATH% || GOTO :ERROR
    ttx -o %FINAL_EMJ_FONT_PATH% -m %EMOJI_FONT_PATH% "emjname.ttx" || GOTO :ERROR
    DEL "emjname.ttx"
)

ECHO Creating new Segoe UI Symbol font from EmojiOne
REM Merge Segoe UI Symbol into EmojiOne, this keeps emoji one's glyph ids intact
REM for the 'SVG ' table data
pyftmerge %EMOJI_FONT_PATH% %MS_FONT_PATH%
REM pyftmerge doesn't generate a cmap4 table if either font has a cmap12 table
python %CMAP_SCRIPT% "merged.ttf" "mergedc4.ttf" || GOTO :ERROR
DEL "merged.ttf"
ECHO Dumping SVG emojis
ttx -t "SVG " -o "svg.ttx" %EMOJI_FONT_PATH% || GOTO :ERROR
ttx -t "name" -o "name.ttx" %MS_FONT_PATH% || GOTO :ERROR
ECHO Merging in dumped emojis
ttx -o "almost.ttf" -m "mergedc4.ttf" "name.ttx" || GOTO :ERROR
DEL "mergedc4.ttf"
DEL "name.ttx"
ttx -o %FINAL_FONT_PATH% -m "almost.ttf" "svg.ttx" || GOTO :ERROR
DEL "almost.ttf"
DEL "svg.ttx"
REM Get back to working directory.
POPD

ECHO.
ECHO.
IF EXIST %MS_EMOJI_FONT_PATH% (
    ECHO The fonts are now saved in
    ECHO %FINAL_FONT_PATH%
    ECHO and
    ECHO %FINAL_EMJ_FONT_PATH%
    ECHO After installation, the original fonts will still be located at
    ECHO %MS_FONT_PATH%
    ECHO and
    ECHO %MS_EMOJI_FONT_PATH%
) ELSE (
    ECHO The font is now saved in
    ECHO %FINAL_FONT_PATH%
    ECHO After installation, the original font will still be located at
    ECHO %MS_FONT_PATH%
)
ECHO It is not overwritten, and can be reinstalled with uninstall.cmd
ECHO To finish installation, the font will be opened for you to install.
ECHO.
ECHO If the font is in a network path, copy to a local disk and
ECHO double click to install.
ECHO Press the [INSTALL] button in the Font Viewer, then close the viewer.
CHOICE /m "Would you like to install the fonts now?"
IF ERRORLEVEL 2 (
    EXIT /b
)
ECHO.
ECHO Running the font installer for Segoe UI Symbol
REM The font viewer doesn't like quotes for some reason, but is fine with paths with spaces.
fontview %FINAL_FONT_PATH_NO_QUOTES%
if EXIST %MS_EMOJI_FONT_PATH% (
    ECHO.
    ECHO Running the font installer for Segoe UI Emoji
    fontview %FINAL_EMJ_FONT_PATH_NO_QUOTES%
)
ECHO.
ECHO All Done!
PAUSE
EXIT /b

:ERROR
ECHO Installation failed!
PAUSE
EXIT /b %ERRORLEVEL%