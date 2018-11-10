object ConfigForm: TConfigForm
  Left = 189
  Top = 117
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Konfiguration'
  ClientHeight = 313
  ClientWidth = 361
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object btnAbbrechen: TButton
    Left = 8
    Top = 280
    Width = 113
    Height = 25
    Cancel = True
    Caption = 'Abbrechen'
    TabOrder = 0
    OnClick = btnAbbrechenClick
  end
  object btnSpeichern: TButton
    Left = 240
    Top = 280
    Width = 113
    Height = 25
    Caption = 'Speichern'
    Default = True
    TabOrder = 1
    OnClick = btnSpeichernClick
  end
  object grpMusikOrdner: TGroupBox
    Left = 8
    Top = 8
    Width = 345
    Height = 257
    Caption = 'Musikordner'
    TabOrder = 2
    object lstMusikOrdner: TListBox
      Left = 16
      Top = 24
      Width = 201
      Height = 209
      ItemHeight = 13
      TabOrder = 0
    end
    object btnOrdnerErstellen: TButton
      Left = 232
      Top = 24
      Width = 97
      Height = 25
      Caption = 'Neuer Ordner'
      TabOrder = 1
      OnClick = btnOrdnerErstellenClick
    end
    object btnOrdnerEntfernen: TButton
      Left = 230
      Top = 56
      Width = 99
      Height = 25
      Caption = 'Entfernen'
      TabOrder = 2
      OnClick = btnOrdnerEntfernenClick
    end
  end
end
