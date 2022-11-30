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

### PART III - VideoComposition rendering with Metal(11/29)
- 將會介紹如何用MetalKit處理VideoComposition的渲染部分，包含：
  - 實作時的注意事項，Metal的座標系統，以及一點點點最基本Metal language的說明
  - 如何並行播放＆與圖片混合播放
  - 如何做客製化轉場
### PART IV - AudioMix
