; ====================================================================================================
; MSX BIOS
; ====================================================================================================
RDVRM:		            EQU $004A	; BIOS RDVRM
WRTVRM:		            EQU $004D	; BIOS WRTVRM
FILVRM:			        EQU	$0056	; BIOS VRAM指定領域同一データ転送
LDIRVM:			        EQU	$005C	; BIOS VRAMブロック転送
CHGMOD:                 EQU $005F   ; BIOS スクリーンモード変更
GICINI:	                EQU $0090	; PSGの初期化アドレス
WRTPSG:	                EQU $0093   ; PSGレジスタへのデータ書込アドレス
ERAFNC:                 EQU $00CC   ; BIOS ファンクションキー非表示
GTSTCK:                 EQU $00D5   ; BIOS ジョイスティックの状態取得
GTTRIG:                 EQU $00D8   ; BIOS トリガボタンの状態取得
SNSMAT:                 EQU $0141   ; BIOS キーマトリクススキャン
KILBUF:                 EQU $0156   ; BIOS キーバッファクリア
