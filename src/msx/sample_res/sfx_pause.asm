_SFX_PAUSE:
    DB  200
    DW  _SFX_PAUSE_TRK1
    DW  _SFX_PAUSE_TRK2
    DW  _SFX_PAUSE_TRK3
_SFX_PAUSE_TRK1:
    DB  217, %10, 212, 52, 3, 209, 52, 3, 212, 57, 3, 209, 57, 3, 212, 60
    DB  3, 209, 60, 3, 212, 64, 3, 209, 64, 3
    DB  255
_SFX_PAUSE_TRK2:
    DB  218, 1
    DB  217, %10, 212, 55, 3, 209, 55, 3, 212, 50, 3, 209, 50, 3, 212, 55
    DB  3, 209, 55, 3, 212, 67, 3, 209, 67, 3
    DB  255
_SFX_PAUSE_TRK3:
    DB  217, %10, 212, 55, 3, 209, 55, 3, 212, 50, 3, 209, 50, 3, 212, 55
    DB  3, 209, 55, 3, 212, 67, 3, 209, 67, 3
    DB  255