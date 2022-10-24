# AVCompositionDemo

本系列將分成三部分：

### PART I - AVComposition 的簡介 (9/13)
- 將介紹如果使用AVComposition，你大致需要實作＆經過什麼流程
- 主要是先有個概觀，不會說明最複雜的VideoComposition內部實做
- 範例將帶過：
  - 影片的播放
  - 對播放時間的調整
  - 串連兩個影片(但不包含VideoComposition部分)

### PART II - AVVideoComposition的實做 (10/25)
  - 將會介紹如何藉由AVVideoComposition，進階控制影片的播放，主要為：
    - AVMutableVideoComposition的使用，包含：
      -  影片的轉場
      - 同時並行播放複數個影片
    - 自定義CustomVideoComposition，包含：
      - 製作浮水印，或在影片上蓋圖片
      - 影片的轉場
  - 本次將重點著重在 AVVideoComposition 的介紹，故會暫以Apple的MetalRenderer代為處理Metal部分的操作

### PART III - AVVideoComposition後續＆AVAudioMix (11/22)
- 將會介紹AVVideoComposition剩餘部分，包含：
 -  CustomVideoComposition 搭配 Metal 的使用
 - 如何處理圖片/影片混合播放
 - 影片播放上時覆蓋另一影片 / 動畫
 - 如果時間足夠，將會包含AVAudioMix部分
