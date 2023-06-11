[ [Engligh](README.md) | [日本語](README.ja.md) ]  

---

# PSGSoundDriver for MSX

## Overview

This is a PSG sound driver for MSX.  
It is in a form that can be compiled with z88dk (zcc). 
Supported functions are as follows:  
- Supports interrupted playback of sound effects  
- Playback priority can be set for sound effects  
- Supports noise ON/OFF, tone, noise tone, volume, and detuning  
- Data created with LovelyComposer can be converted with `lc2asm.py` (with restrictions)

## Execution Sample

You can check the execution sample with WebMSX at the following URL.    

https://webmsx.org/?MACHINE=MSX1J&ROM=https://github.com/aburi6800/msx-PSGSoundDriver/raw/master/dist/sample.rom&FAST_BOOT


## How to build

### To use cmake:

Edit the `CMakeLists.txt` included in this project to specify the source for this player (`psgdriver.asm`) and the source you created.   
For example, the sample program defines the following.  
```
add_source_files(
    ./src/msx/sample.asm
    ./src/msx/psgdriver.asm
)
```

Next, run the following command in the project root directory to generate the make file.   
(First time only; not necessary after the second time)  
```
$ mkdir build && cd build
$ cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/z88dk.cmake ..
```

Execute the following command in the `build` directory to build.  
```
$ make clean && make
```

The `.rom` file will be created in the `dist` directory.  

### To use the zcc command:

Enter the source directory and execute the following command (replace the source file name with your own)  
This command is the same for both assembler and C.  
For details on other options, such as specifying the path to the include file, see the help displayed by `zcc -h`.  
```
$ zcc +msx -create-app -subtype=rom psgdriver.asm sample.asm -o=../../dist/build.rom 
```
### For use with assemblers such as z88dk-z80asm

You can also use z88dk-z80asm or other assemblers included in z88dk.  
See [z88dk-z80asm documentation](https://github.com/z88dk/z88dk/wiki/Tool---z80asm) for more information.  
Other assemblers also use few z88dk-specific features such as macros, which can be handled with a few modifications.  
>Note :  
>The area after the label definition part below is a work area.  
If you compile with >zcc, it will be properly addressed, otherwise specify ORG to be addressed to RAM area($8000~, etc.).
>- SOUNDDRV_WORKAREA : 120byte  
>
>This breakdown is as follows. (do not change the order of placement)
>- SOUNDDRV_H_TIMI_BACKUP : 5byte
>- SOUNDDRV_STATE : 1byte
>- SOUNDDRV_WK_MIXING_TONE : 1byte
>- SOUNDDRV_WK_MIXING_NOISE : 1byte
>- SOUNDDRV_BGMWK : 48byte
>- SOUNDDRV_DUMMYWK : 16byte
>- SOUNDDRV_SFXWK : 48byte

## How to use

### Prepare the program to be used

- At the beginning of the program source you have created, add the following definition:
```
EXTERN SOUNDDRV_INIT
EXTERN SOUNDDRV_EXEC
EXTERN SOUNDDRV_BGMPLAY
EXTERN SOUNDDRV_SFXPLAY
EXTERN SOUNDDRV_STOP
EXTERN SOUNDDRV_PAUSE
EXTERN SOUNDDRV_RESUME
EXTERN SOUNDDRV_STATUS
```
- Next, CALL the driver initialization routine (`SOUNDDRV_INIT`) in the initial processing of the program.
    - In this initialization routine, the H.TIMI hook code (5 bytes) is backed up and rewritten to run the driver.
    - If your program has a process that runs on the `H.TIMI` hook, be sure to make a 5-byte backup from `H.TIMI` yourself and `JP` to the backed up address at the end of the process.
    - Note that the timing of `CALL` of this driver's initialization routine by the application can be either before or after the `H.TIMI` hook is rewritten.
```
    CALL SOUNDDRV_INIT              ; Initialize sound driver
```
### How to specify, play and stop playback data

- See the following "Driver API" section.

### Driver APIs

After the above preparation, the driver can be controlled by following the steps below.

- `SOUNDDRV_BGMPLAY`
    - Starts playing BGM.
    - Specify the address of the BGM data to be played in the `HL` register.
```
    LD HL,BGMDATA
    CALL SOUNDDRV_BGMPLAY           ; BGM data play start
```
- `SOUNDDRV_SFXPLAY`
    - Play the sound effect.
    - If a sound effect with a higher priority than the specified sound effect is being played, it is not played.
    - When the playback of the sound effect is finished, the BGM playback is restored.
    - Specify the address of the sound effect data to be played in the `HL` register.
```
    LD HL,SFXDATA
    CALL SOUNDDRV_SFXPLAY           ; SFX data play start
```
- `SOUNDDRV_STOP`
    - Stops the playback of background music and sound effects.
```
    CALL SOUNDDRV_STOP              ; BGM and SFX stop
```
- `SOUNDDRV_PAUSE`
    - Pause playback of background music and sound effects.
```
    CALL SOUNDDRV_PAUSE             : BGM and SFX pause
```
- `SOUNDDRV_RESUME`
    - Unpause BGM and sound effects.
    - If called during playback, nothing is processed.
```
    CALL SOUNDDRV_RESUME            ; BGM and SFX unpause
```
- `SOUNDDRV_STATUS`
    - Obtain driver status.
    - Bit 0 is 1 if playback is in progress and 0 if stopped.
    - Bit 1 is set to 1 if the program is paused, otherwise it is set to 0.
```
    LD A,(SOUNDDRV_STATUS)          ; get driver status
```

## Data Structures

The data structure handled by this driver is the following image.  
Both BGM and sound effects will have the same composition.  
```
[BGM/SFX Data]
  +- [Priority]
  +- [Track 1 data address]
  +- [Track 2 data address]
  +- [Track 3 data address]
[Track 1 data]
[Track 2 data]
[Track 3 data]
```
> In other words, data created as sound effects can be played as background music, and vice versa.  
> Also, as described above, since a collection of track data is used as song data, the same track can be used for multiple background music/sound effects.  
> 

### BGM/SFX Data

The BGM/SFX data consists of the following:  

- priority(1byte)：0～255 (Low to high) Effective only when playing sound effects; ignored for background music.  
- Track 1 data address(2byte)：If not, set `$0000`.  
- Track 2 data address(2byte)：If not, set `$0000`.  
- Track 3 data address(2byte)：If not, set `$0000`.  

### Track data

The track data consists of the following:  

| Command | Function | Overview |
|:---|:---|:---|
| 0〜95<br>($00〜$5F) | note number<br>(See "Note Number Table" below for setting values) | Specified in the format 0 to 95,<value>. The value specifies the note length (n/60). <br>See "About Tone Length" below for more information about note length. |
| 200〜215<br>($CB〜$D7) | volume | Corresponds to command values 0 to 15. (Same as the value set in PSG registers #8 to #10) |
| 216<br>($D8) | noise tone | Specified in the format of 216,<value>. Specify 0 to 31 for the value. (Same as the value set in PSG register #6) |
| 217<br>($D9) | mixing | Specified in the format of 217,<value>. Specify 0 to 3 for the value. (bit0=Tone/bit1=Noise, 1=off/0=on)<br>Example) %10 = Tone ON, Noise OFF |
| 218<br>($DA) | detune | Specified in the format 218,<value>. The value specifies the correction value for the note. |
| 253<br>($FD)| start of loop position | When looping at the end of data, the loop starts with the data at this address. |
| 254<br>($FE) | End of data (return to track start or loop start position) | Returns to the position specified by command 243. If there is no command 243, returns to the beginning. |
| 255<br>($FF) | End of data (end of playback) | (none) |

### Note Number Table

The note number (scale) is set to the following tone table value.

| octave | C | C+<br>(D-) | D | D+<br>(E-) | E | F | F+<br>(G-) | G | G+<br>(A-) | A | A+<br>(B-) | B |
| :---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| o1 | $00 | $01 | $02 | $03 | $04 | $05 | $06 | $07 | $08 | $09 | $0A | $0B |
| o2 | $0C | $0D | $0E | $0F | $10 | $11 | $12 | $13 | $14 | $15 | $16 | $17 |
| o3 | $18 | $19 | $1A | $1B | $1C | $1D | $1E | $1F | $20 | $21 | $22 | $23 |
| o4 | $24 | $25 | $26 | $27 | $28 | $29 | $2A | $2B | $2C | $2D | $2E | $2F |
| o5 | $30 | $31 | $32 | $33 | $34 | $35 | $36 | $37 | $38 | $39 | $3A | $3B |
| o6 | $3C | $3D | $3E | $3F | $40 | $41 | $42 | $43 | $44 | $45 | $46 | $47 |
| o7 | $48 | $49 | $4A | $4B | $4C | $4D | $4E | $4F | $50 | $51 | $52 | $53 |
| o8 | $54 | $55 | $56 | $57 | $58 | $59 | $5A | $5B | $5C | $5D | $5E | $5F |

### About Tone Length

Tone can be obtained by:  

- Note length per second: tempo / 60  
- Quarter note length: 60 / (note length per second)  
- Eighth note length: quarter note length / 2  
- 16th note length: 8th note length / 2  

Example: Tempo = 120 (= speed of 120 quarter notes per minute)  
- Note length per second: 120 / 60 = 2  
- Quarter note length: 60 / 2 = 30  
- Eighth note length: 30 / 2 = 15  
- 16th note length: 15 / 2 = 7.5  
 
> Set an integer for the data. If there are decimals, adjust so that the sum is the sum of the note lengths.  


## Conversion tool (`lc2asm.py`) from LovelyComposer

### Overview

A tool is available to convert data created with the "LovelyComposer" composition tool into data for this driver. (`src/python/lc2asm.py`)  
Python is required, so please install it separately.  

LovelyComposer can be purchased at the following sites.  
[BOOTH](https://booth.pm/ja/items/3006558)  
[itch.io](https://1oogames.itch.io/lovely-composer)  

### How to use

Go to the directory where lc2asm.py is located and run the following to create an .asm file at the location where the .jsonl file is located.  
```
python lc2asm.py <.jsonl filepath>
```
The created .asm file should be imported directly into the source or `INCLUDE`.  
The options that can be specified are as follows:  
- --outfile/-o : Specify output file path  
- --force/-f : overwrite output file  
- --version/-v : display version  
- --help/-h : display help  

### Supported Features

The following features of LovelyComposer are supported:  

- Supports volume specification for each note
- Loop start/end position specification
- Change the number of notes per page and tempo

### Restrictions

Data conversion has the following limitations to LovelyComposer's functionality:

- The two available tones are "SQUARE WAVE" and "NOISE".
- The three available channels are 1-3. Channel 4 and code channels are ignored.
- Tempo is not an exact match, but an approximation.
- The pan specification is ignored.

## Release notes

2023/06/11  Version 1.6.1
- lc2asm.py  
    - Fixed a bug that caused output file labels to be full paths.  

2023/06/10  Version 1.6
- lc2asm.py  
    - Corrected processing around input and output file paths, added options  

2023/02/12  Version 1.5.1  
- psgdriver.asm  
    - Abolished "include" and added a label at the beginning of the work area    

2022/08/14  Version 1.5.0  
- psgdriver.asm  
    - Added pause (`SOUNDDRV_PAUSE`)/resume (`SOUNDDRV_RESUME`) API  
    - Added API (SOUNDDRV_STATUS) to obtain driver status  

2022/08/06  Version 1.4.1  
- psgdriver.asm  
    - Fixed path delimiter error in includes  

2022/07/24  Version 1.4.0  
- psgdriver.asm  
    - SFX playback now also determines the priority of the BGM.  
        (SFX will not be played while BGM with the highest priority is playing.)  

2022/05/29  Version 1.3.0  
- psgdriver.asm  
    - Version notation modified to match semantic versioning  
    - Modified to save backup and CALL at the end of processing to allow call chaining of H.TIMI hooks.  
- lc2asm.py  
    - Version notation modified to match semantic versioning  

2022/05/07  Version 1.20  
- psgdriver.asm  
    - Volume data configuration changes, along with data changes for other commands.  
    Please note that this is not compatible with the previous version up to 1.1.  
- lc2asm.py  
    - Support for volume data configuration changes, as well as data changes for other commands.  

2021/12/04  Version 1.11
- lc2asm.py  
    - Support for changing the number of notes and SPEED values per page and the number of all pages.  

2021/11/28  Version 1.10  
- psgdriver.asm  
    - LovelyComposer's support for specifying the loop start/end position  
- lc2asm.py  
    - Modified to output data with loop when end of loop is specified, and without loop when not specified.  

2021/11/19  Version 1.00  
- psgdriver.asm  
    - initial creation  
- lc2asm.py  
    - initial creation
