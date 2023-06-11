# -*- coding: utf-8 -*-
# ====================================================================================================
#
# lc2asm.py
#
# licence:MIT Licence
# copyright-holders:Hitoshi Iwai(aburi6800)
#
# ====================================================================================================

# 概要：
# LovelyComposerのデータをMSX用のASMソース形式に変換する。
#
# 仕様：
# - LCのjsonデータから、ChA～Cのデータを対象として処理する。ChD、コードのデータは無視する。
# - speed値を1/2として、1ノートの音長とする(1未満=1とする)
# - トーン('n')
#   - o4aはlc＝69,ドライバのデータ=45なので、以下で計算。
#       value - 24
#     ※MSXではo8まで指定可能だが、lcではo7までになる
#   - 連続して同じトーンが出てきても、別データとして生成する。
#       例) T150でCDEE → c,8,d,8,e,8,e,8 のイメージ(実際は音階はテーブルのidx値)
#   - トーンが無い(=none)場合は、音階0、ボリューム0で音長のみ設定したデータとする
#   - LCSoundの要素(32個)全てnoneのデータが出てきたら、そこでチャネルの処理を終了する(255)
#   - 音長は以下で計算する。
#       (speed / 2) (端数切捨) ※ここは結構影響が大きいので、後で要調整
# - ボリューム('x')
#   - LCも1～15のためそのままの値を使用、+200してデータとする。
#   - 直前のデータと値が変わらない場合はデータを出力しない。
# - PSGR#7 (ノイズ/トーンのミキシング)
#   - 以下の音色はノイズとし、以外をトーンとする
#       id=4
#   - 直前のトーンが同じ(ノイズ→ノイズ、トーン→トーン)場合は変更不要とする
#   - LCの音色でノイズとトーンを同時に出すものがないので（だよね？）、常にどちらかとなる。
# - PSGR#6 (ノイズトーン)
#   - ノイズの場合に対象のトーンにより決定、以下で計算する。([低]MSX32/lc24～[高]MSX0/lc107)
#       (107 - value) / 2.59 (端数切捨)
# - ハードウェアエンベロープは使わない。(複数チャンネルで波形が同じになるため、使いにくい)
# - ファイル出力はLCSoundデータ単位に行う(=LCVoiceの要素、32トーン)
# - LCで1ぺージのノート数、speed、全ページ数を変更した場合、それに従ったデータを出力する。

import json
import os
import sys
import traceback
import argparse

def main():
    '''
    変換処理実行
    '''
    # 引数パース
    _argparser = argparse.ArgumentParser(description="Convert .asm data from a LovelyComposer music data(.jsonl file).")
    _argparser.add_argument("infile", help=".jsonl filepath.")
    _argparser.add_argument("--outfile", "-o", help=".asm filepath for output.", default="")
    _argparser.add_argument("--force", "-f", action="store_const", const="", help="Ignore output even if the file exists.")
    _argparser.add_argument("--version", "-v", action="version", version="%(prog)s 1.6.0")
    _args = _argparser.parse_args()

    # 入力ファイルのフルパスを設定
    _inFilePath = filePathUtil(_args.infile)

    # 出力ファイルのフルパスを設定
    _outFilePath = ""
    if _args.outfile != "":
        _outFilePath = filePathUtil(_args.outfile)

    # 引数チェック
    try:
        # 入力ファイルの拡張子は.jsonl以外はエラー
        if os.path.splitext(_args.infile)[1] != ".jsonl":
            raise Exception("File extension is not '.jsonl' " + _inFilePath)

        # 入力ファイルの存在チェック
        if os.path.exists(_inFilePath) == False:
            raise Exception("File not found " + _inFilePath)

        # 出力ファイルが省略された場合は入力ファイルパスの拡張子を .asm とする
        if _outFilePath == "":
            _outFilePath = os.path.splitext(_inFilePath)[0] + ".asm"

        # 存在チェック
        # オプション --force(-f)が設定されている場合はエラーとしない
        if os.path.exists(_outFilePath) and _args.force == None:
            raise FileExistsError("Specified file already exists " + _outFilePath)

    except Exception as e:
        print(traceback.format_exception_only(type(e), e)[0])
        sys.exit()

    # 出力データクラスを初期化
    dc = dataClass(_inFilePath, _outFilePath)

    # 変換処理実行
    dc.convert()

    # 出力データクラスからファイルに出力
    dc.export()

def filePathUtil(path:str) -> str:
    '''
    ファイルパスユーティリティ\n
    引数のパスにディレクトリを含んでいない場合、カレントディレクトリを付与したフルパスを生成して返却します。\n
    \n
    Parameters\n
    ----------\n
    path : str\n
        ファイルパス
    \n
    Returns\n
    -------\n
    str\n
        フルパスに編集後の文字列\n
    '''
    # 入力ファイルのフルパスからファイル名を取得
    _filename = os.path.basename(path)

    # 入力ファイルのフルパスからファイルパスを取得
    _filepath = os.path.dirname(path)
    if _filepath == "" or _filepath == None:
        # ファイルパスが取得できなかった場合（ファイル名のみ指定された場合）は現在のパスを設定
        _filepath = os.path.dirname(__file__)

    return _filepath + os.sep + _filename

class dataClass:
    '''
    出力データクラス
    '''
    # jsonデータのリスト
    data_header = []
    data_body = []

    # ダンプデータ
    dumpData = [0, 0, 0]

    # ベースとなるspeed値
    speed = 0

    # 最大ページ数
    maxPage = 0

    # １ページあたりのノート数
    noteParPage = 0

    # 開始ページ数
    startPage = 0

    # 最終ページ数
    endPage = 0

    # ループ有無フラグ
    isLoop = False

    # 入力ファイルパス
    inFilePath = ""

    # 出力ファイルパス
    outFilePath = ""

    # 各値の退避変数を初期化
    svVoice = None
    svNote = None
    svVolume = None
    svNoiseTone = None
    svMixing = None

    def __init__(self, _inFileName:str = "", _outFileName:str = ""):
        '''
        初期化処理
        \n
        Parameters\n
        ----------\n
        _inFileName : str\n
        入力ファイルのフルパス\n
        _outFileName : str\n
        出力ファイルのフルパス\n
        \n
        Returns\n
        -------\n
        なし\n
        '''
        # 引数のjsonFileNameのjsonファイルを読み込み
        self.inFilePath = _inFileName

        # 出力ファイル名を設定
        self.outFilePath = _outFileName

        print("input  [" + self.inFilePath + "]")
        print("output [" + self.outFilePath + "]")

        # 入力ファイルオープン
        with open(self.inFilePath) as f:
            # ヘッダ部
            df_header = f.readline()
            # ボディ部
            df_body = f.readline()

        # jsonデータをパース（ヘッダ部）
        self.data_header = json.loads(df_header)
        # jsonデータをパース（ボディ部）
        self.data_body = json.loads(df_body)

    def convert(self):
        '''
        変換処理
        '''
        # speed値取得
        self.speed = int((self.data_body["speed"]) / 1.8)
        print("speed = " + str(self.speed))

        # 最大ページ数取得
        self.maxPage = int(self.data_body["pages"])

        # 各チャネルのデータを取得
        channels = (self.data_body["channels"])["channels"]
        channelList = list(channels)

        # 開始ページ数設定
        self.getStartPage(self.data_body)

        # 最終ページ数設定
        self.getEndPage(self.data_body)

        # 出力データサイズ初期化
        totalSize = 0

        # チャネル1～3に大してダンプデータ作成
        for i in range(3):
            self.dumpData[i] = self.makeDumpData(channelList[i])
            print("track" + str(i+1) + ":" + str(len(self.dumpData[i])) + "bytes.")
            totalSize += len(self.dumpData[i])

        print("total :" + str(totalSize) + "bytes.")

    def getStartPage(self, dataBody):
        '''
        開始ページ数取得
        '''
        # 初期値はゼロとする
        startPage = 0

        # ループスタートが指定されている場合は、そのページ数を返却する
        loopStartBar = dataBody["loop_start_bar"]
        if loopStartBar != None:
            startPage = loopStartBar
            print("loop start page = " + str(loopStartBar))

        self.startPage = startPage

    def getEndPage(self, dataBody):
        '''
        終了ページ数取得
        '''
        # ループエンドが指定されている場合は、そのページ数を返却する
        loopEndBar = dataBody["loop_end_bar"]

        if loopEndBar != None:
            endPage = loopEndBar + 1
            self.isLoop = True
            print("loop end page = " + str(endPage))

        else:
            # ループエンドが未指定の場合は、1〜3チャンネルを順に末端から走査して、最終ページ数を返却する
            # ページ中にデータが存在しないページ-1を最終ページとするが、1〜3チャンネルで最大のページ数とする
            channels = dataBody["channels"]
            channelList = channels["channels"]
            endPage = 0
            for i in range(3):
                soundList = channelList[i].get("sl")
                for idx, sl in enumerate(reversed(soundList)):
                    if self.isBlankPage(sl.get("vl")) == False:
                        if endPage < idx:
                            endPage = idx
                        break
            endPage = self.maxPage - endPage
            print("play end page = " + str(endPage))

        self.endPage = endPage

    def isBlankPage(self, voiceList):
        '''
        ブランクページ判定
        @return bool
        '''
        isBlank = True
        if voiceList == None:
            return isBlank

        for val in enumerate(voiceList):
            if (val[1].get("n") is None):
                pass
            else:
                isBlank = False
                break

        return isBlank

    def makeDumpData(self, argData):
        '''
        ダンプデータ作成処理
        引数のチャンネルデータからダンプデータを生成する
        '''
        # 各値の退避変数を初期化
        self.svVoice = None
        self.svNote = None
        self.svVolume = None
        self.svNoiseTone = None
        self.svMixing = None

        # 音長
        time = 0

        sv = {}

        # データバッファ
        buffer = []

        # 'sl'要素を取り出す
        sl = argData["sl"]

        # sl要素の全てに対して繰り返す(0～最大ページ数)
        for idx in range(self.endPage):
            vl = sl[idx]
            sv = vl["vl"][0]
            # ver1.2.0未満のデータ対応
            # sv["x"]が存在しなければ固定値で追加する
            if "x" not in sv:
                sv["x"] = 12

            # speed値取得
            self.speed = int((vl["play_speed"]) / 1.8)

            # 音長をリセット
            time = 0

            # 処理対象がゼロ以外でstartPageである場合は、ループ開始データをバッファに追加する
            if idx > 0 and idx == self.startPage:
                buffer += ["253"]

            # vl要素の全てに対して繰り返す(0～31)
            notes = int(vl["play_notes"])

            for idx in range(notes):
                v = vl["vl"][idx]
                # ver1.2.0未満のデータ対応
                # v["x"]が存在しなければ固定値で追加する
                if "x" not in v:
                    v["x"] = 12

                # voice,tone,volumeのいずれかが直前のデータと違っていたら、退避していaddBufferを呼ぶ
                # ただし一番最初のデータ時は直前の値が全てNoneなので何もしない
                if v["n"] != sv["n"] or v["id"] != sv["id"] or v["x"] != sv["x"]:
                    buffer += self.addBuffer(sv, time)

                    # データを退避
                    sv = v

                    #音長をリセット
                    time = 0
                
                # 次に音長をカウントした時に255を超えるのであれば、バッファに出力
                if (time + self.speed > 255):
                    buffer += self.addBuffer(sv, time)

                    #音長をリセット
                    time = 0

                # 音長をカウント
                time += self.speed

            # 最後のデータに対するバッファ出力
            buffer += self.addBuffer(v, time)

        return buffer

    def addBuffer(self, vl, time):
        '''
        バッファ追加処理\n
        引数の値からbufferにデータを追加する。\n
        ただし、前回の設定値から変わっていないパラメータは設定しない。\n
        追加するのは以下順とする。\n
        1) mixing\n
        2) volme\n
        3) note or noiseTone\n
        '''
        dataList = []

        # voiceが前回の設定値から変わったか判定する
        # 変わった場合はコマンド(217)とPSGR#7の設定値をバッファに出力する
        if self.svVoice != vl["id"] and vl["id"] != None:
            mixing = self.getMixingValue(vl["id"])
            if mixing != self.svMixing:
                # ミキシングの値が変わった場合のみバッファに出力する
                dataList += ["217", mixing]
                self.svMixing = mixing
                self.svVoice = vl["id"]

        # volumeが前回の設定値から変わったか判定する
        # 変わった場合はコマンド(200+PSGR#8〜10に設定値)をバッファに出力する
        if vl["n"] == None:
            # 一度noteを置いて削除した場合、noteがNoneでもvolumeが設定されているため、対処する
            vl["x"] = 0
        if self.svVolume != vl["x"]:
            dataList += [str(self.getVolumeValue(vl["x"]))]
            self.svVolume = vl["x"]

        # noteは無条件でバッファに出力する
        if self.svMixing == "%01":
            # ノイズの時の処理
            # 変わった場合はコマンド(216)とPSGR#6の設定値をバッファに出力する
            noiseTone = self.getNoiseToneValue(vl["n"])
            if noiseTone != self.svNoiseTone:
                dataList += ["216", str(noiseTone)]
                self.svNoiseTone = noiseTone
            dataList += [str(self.getNoteValue(vl["n"])), str(time)]
        else:
            # トーンの時の処理
            dataList += [str(self.getNoteValue(vl["n"])), str(time)]

        return dataList


    def getNoteValue(self, tone):
        '''
        トーン値取得処理
        '''
        return (tone - 24 if tone != None else 0)

    def getNoiseToneValue(self, tone):
        '''
        ノイズトーン値取得処理
        '''
        return int((107-int(tone if tone != None else 1))/2.59)

    def getMixingValue(self, voice):
        '''
        ミキシング値取得処理
        '''
        return ("%01" if voice == 3 else "%10")

    def getVolumeValue(self, volume):
        '''
        ボリューム値取得処理
        '''
#        return int(volume*1.25)
        return int(200+volume) # lcのVolume値+200(200〜215)

    def export(self):
        '''
        ファイルエクスポート処理
        '''
        # ラベル名
#        outFilePath = os.path.normpath(os.path.join(os.path.dirname(__file__), self.outFilePath + ".asm"))
        labelName = "_" + os.path.splitext(os.path.basename(self.outFilePath))[0]
        print("Label :" + labelName)

        with open(self.outFilePath, mode="w") as f:
            # ヘッダー情報
            f.write(labelName + ":\n")
            f.write("    DB  0\n")
            for idx in range(3):
                if len(self.dumpData[idx]) > 0:
                    f.write("    DW  " + labelName + "_TRK" + str(idx+1) + "\n")
                else:
                    f.write("    DW  $0000\n")

            # 各チャンネルのデータ
            for idx, ch in enumerate(self.dumpData):
                if len(ch) == 0:
                    break
                else:
                    f.write(labelName + "_TRK" + str(idx+1) + ":\n")
                    s = ""
                    for i, v in enumerate(ch):
                        if i % 16 == 0:
                            if s != "":
                                f.write("    DB  " + s + "\n")
                            s =  str(v)
                        else:
                            s += ", " + str(v)
                    if s != "":
                        f.write("    DB  " + s + "\n")
                    if self.isLoop:
                        f.write("    DB  254\n")
                    else:
                        f.write("    DB  255\n")

        print("export complete.")

if __name__ == "__main__":
    main()
